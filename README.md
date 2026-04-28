# 🌱 AgroMarket POS — Flutter App

Application mobile POS (Point of Sale) pour les opérateurs de terrain de la plateforme de marché agricole.

**Technologie :** Flutter 3.x • Dart • Riverpod • go_router • Dio

---

## 📱 Fonctionnalités

- ✅ Login sécurisé (Sanctum token) + déconnexion automatique sur 401
- ✅ Navigation différenciée par rôle (Admin / Supervisor / Operator)
- ✅ Admin : gestion des superviseurs (liste + création)
- ✅ Supervisor : gestion des opérateurs (liste + création)
- ✅ Recherche agriculteur (nom, ID, téléphone) + pull-to-refresh
- ✅ Création de profil agriculteur
- ✅ Navigation catalogue par catégories imbriquées
- ✅ Ajout/suppression produits dans le panier
- ✅ Checkout (cash ou crédit avec intérêt)
- ✅ Consultation dettes avec barre de progression
- ✅ Remboursement en kg (aperçu conversion + confirmation)
- ✅ Interface adaptée mobile + tablette

---

## 🚀 Installation

### Prérequis
- Flutter 3.10+
- Dart 3.0+
- Android Studio / Xcode

```bash
# 1. Cloner
git clone https://github.com/VOTRE_USERNAME/farmers-market-app.git
cd farmers-market-app

# 2. Installer les dépendances
flutter pub get

# 3. Configurer l'URL de l'API
# Éditer lib/core/constants/app_constants.dart
# Changer baseUrl selon votre environnement :
#   Android émulateur : http://10.0.2.2:8000/api
#   iOS simulateur    : http://localhost:8000/api
#   Production        : https://votre-api.railway.app/api

# 4. Lancer
flutter run
```

---

## 🌐 Déploiement sur GitHub Pages (Flutter Web)

### Option A — GitHub Actions (automatique, recommandé)

Le workflow `.github/workflows/deploy.yml` inclus dans ce repo fait tout automatiquement à chaque push sur `main`.

**Configuration requise :**
1. Aller dans **Settings → Pages** du repo
2. Source → **GitHub Actions**
3. C'est tout — le workflow se charge du reste !

L'app sera déployée sur : `https://VOTRE_USERNAME.github.io/farmers-market-app/`

### Option B — Manuel

```bash
# 1. Build pour le web
flutter build web --release --base-href="/farmers-market-app/"

# 2. Copier dans /docs
cp -r build/web/* docs/
git add docs/ && git commit -m "deploy web" && git push
# Settings → Pages → Branch: main / /docs
```

> ⚠️ **Important** : Pour que l'app web fonctionne en production, configure `baseUrl` dans `lib/core/constants/app_constants.dart` avec l'URL HTTPS de ton API Railway. Le navigateur bloque les requêtes HTTP depuis une page HTTPS.

---

## 🗂️ Architecture

```
lib/
├── core/
│   ├── api/          # ApiClient (Dio + intercepteurs auth)
│   └── constants/    # AppConstants (baseUrl, clés)
├── features/
│   ├── auth/
│   │   ├── data/     # AuthRepository, AuthUser, AuthState
│   │   └── presentation/ # LoginScreen
│   ├── farmers/
│   │   ├── data/     # FarmerRepository, Farmer models
│   │   └── presentation/ # Search, Detail, Create screens
│   ├── catalog/
│   │   ├── data/     # CatalogRepository, Category, Product
│   │   └── presentation/ # CategoryList, ProductList screens
│   ├── checkout/
│   │   ├── data/     # CartProvider, CheckoutRepository, RepaymentRepository
│   │   └── presentation/ # CheckoutScreen, RepaymentScreen
│   └── debts/
│       └── presentation/ # DebtListScreen
├── router/
│   └── app_router.dart   # GoRouter avec auth guard
├── users/
│   │   ├── data/         # UserRepository, AppUser (supervisors / operators)
│   │   └── presentation/ # UserManagementScreen
│   └── debts/
│       └── presentation/ # DebtListScreen
├── router/
│   └── app_router.dart   # GoRouter + auth guard + protection /users par rôle
└── shared/
    └── widgets/          # MainScaffold + drawer dynamique par rôle
```

### Navigation par rôle

| Rôle | Drawer |
|------|--------|
| `admin` | Agriculteurs · Catalogue · Commande · **Gestion Superviseurs** |
| `supervisor` | Agriculteurs · Catalogue · Commande · **Gestion Opérateurs** |
| `operator` | Agriculteurs · Catalogue · Commande |

**State Management :** Riverpod (`StateNotifierProvider`, `FutureProvider`, `Provider`)

---

## 🧪 Comptes de test

Se connecter avec :
```
Email    : operator@farmersmarket.ci
Password : password123
```

---

## 📹 Workflow utilisateur

1. **Login** → Token stocké dans `flutter_secure_storage`
2. **Rechercher agriculteur** → Sélectionner → Profil + dettes
3. **Nouvelle commande** → Catalogue → Panier → Checkout (cash/crédit)
4. **Remboursement** → Saisir kg cacao → Aperçu conversion → Confirmer
5. **Consulter dettes** → Liste FIFO avec progression visuelle
