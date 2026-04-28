import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../../core/api/api_client.dart';
import '../../../features/farmers/data/farmer_repository.dart';

// ── Cart Model ──────────────────────────────────────────────────────────

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  int get lineTotal => product.priceFcfa * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
    product:  product,
    quantity: quantity ?? this.quantity,
  );
}

class CartState {
  final List<CartItem> items;
  final Farmer? farmer;
  final String paymentMethod; // 'cash' | 'credit'

  const CartState({this.items = const [], this.farmer, this.paymentMethod = 'cash'});

  int get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  CartState copyWith({List<CartItem>? items, Farmer? farmer, String? paymentMethod}) => CartState(
    items:         items         ?? this.items,
    farmer:        farmer        ?? this.farmer,
    paymentMethod: paymentMethod ?? this.paymentMethod,
  );

  CartState clearFarmer() => CartState(items: items, paymentMethod: paymentMethod);
  CartState clearAll()    => const CartState();
}

// ── Notifier ──────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void setFarmer(Farmer farmer) {
    state = state.copyWith(farmer: farmer);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void addProduct(Product product) {
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[existingIndex] = updated[existingIndex].copyWith(
        quantity: updated[existingIndex].quantity + 1,
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: 1)]);
    }
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final updated = state.items.map((item) {
      return item.product.id == productId ? item.copyWith(quantity: quantity) : item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void removeProduct(int productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

// ── Checkout Repository ─────────────────────────────────────────────────

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepository(ref.read(apiClientProvider)),
);

class CheckoutRepository {
  final ApiClient _api;
  CheckoutRepository(this._api);

  Future<Map<String, dynamic>> submitTransaction({
    required int farmerId,
    required List<CartItem> items,
    required String paymentMethod,
    String? notes,
  }) async {
    final res = await _api.post('/transactions', data: {
      'farmer_id':      farmerId,
      'payment_method': paymentMethod,
      'notes':          notes,
      'items': items.map((i) => {
        'product_id': i.product.id,
        'quantity':   i.quantity,
      }).toList(),
    });
    return res.data;
  }
}

// ── Repayment ──────────────────────────────────────────────────────────

final repaymentRepositoryProvider = Provider<RepaymentRepository>(
  (ref) => RepaymentRepository(ref.read(apiClientProvider)),
);

class RepaymentRepository {
  final ApiClient _api;
  RepaymentRepository(this._api);

  Future<Map<String, dynamic>> previewRepayment(int farmerId, double kg) async {
    final res = await _api.post('/repayments', data: {
      'farmer_id':    farmerId,
      'commodity_kg': kg,
      'preview':      true,
    });
    return res.data['data'];
  }

  Future<Map<String, dynamic>> recordRepayment(int farmerId, double kg, {String? notes}) async {
    final res = await _api.post('/repayments', data: {
      'farmer_id':    farmerId,
      'commodity_kg': kg,
      if (notes != null) 'notes': notes,
    });
    return res.data;
  }
}
