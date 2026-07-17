# 💰 Masroufi (مصروفي)

> A personal monthly expense tracker built with Flutter — featuring offline-first architecture, real-time sync, and per-category budget tracking.

**Flutter Bootcamp Final Project** · Dark Mode · Offline-First · Firebase Backend

---

## 📸 Overview

Masroufi helps users track their daily expenses, view spending summaries (today/week/month), and set per-category budget limits. The app works seamlessly offline — expenses are saved locally and synced to the cloud when connectivity is restored.

| Property     | Value                         |
| ------------ | ----------------------------- |
| Platform     | Android (Flutter)             |
| Architecture | Feature-First + Cubit (BLoC)  |
| Backend      | Firebase Auth + Cloud Firestore |
| Local Storage| Hive (offline caching)        |
| Theme        | Dark mode only                |

---

## ✨ Features

- 🔐 **Authentication** — Email/password sign-up & sign-in via Firebase Auth
- ➕ **Add Expenses** — Quick expense entry with category, amount, note, and date
- 📊 **Dashboard** — Real-time summary of today's, this week's, and this month's spending
- 📋 **Monthly Breakdown** — Per-category spending analysis with progress bars
- 💰 **Budget Limits** — Set monthly budget limits per category with overspend alerts
- 📜 **Expense History** — Real-time, date-grouped list with swipe-to-delete
- 📡 **Offline-First** — Expenses save to Hive instantly, sync to Firestore in the background
- 🌱 **Auto Category Seeding** — 7 default categories created on registration

---

## 🏗️ Architecture

The project follows a **Feature-First Architecture** with Cubit-based state management:

```
lib/
├── main.dart                              # Entry point + DI wiring
├── firebase_options.dart                  # Firebase configuration
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                # Color palette + 12 category colors
│   │   ├── app_text_styles.dart           # Outfit/Inter typography system
│   │   ├── app_theme.dart                 # ThemeData (dark mode only)
│   │   └── app_routes.dart                # Named route constants
│   └── widgets/
│       └── app_widgets.dart               # PrimaryButton, AppTextField
└── features/
    ├── auth/                              # Login / Register
    │   ├── data/data_sources/
    │   └── presentation/{cubit, screens}/
    ├── categories/                        # Category model + CRUD
    │   └── data/{models, data_sources}/
    ├── expenses/                          # Add/Edit/Delete expenses
    │   ├── data/{models, data_sources}/
    │   └── presentation/{cubit, screens}/
    ├── dashboard/                         # Spending summaries
    │   ├── data/{models, data_sources}/
    │   └── presentation/{cubit, screens}/
    ├── breakdown/                         # Monthly category analysis
    │   ├── data/{models, data_sources}/
    │   └── presentation/{cubit, screens}/
    └── shell/                             # Bottom nav + Splash
        └── presentation/screens/
```

### Layer Responsibilities

| Layer         | Role                                                |
| ------------- | --------------------------------------------------- |
| **Models**    | Data classes with Firestore + Hive serialization     |
| **Data Sources** | Business logic, Firebase/Hive operations          |
| **Cubits**    | State management (emit states based on data source results) |
| **Screens**   | UI layer consuming states via `BlocBuilder`/`BlocConsumer` |

---

## 🔧 Tech Stack

| Technology          | Purpose                        | Why                                              |
| ------------------- | ------------------------------ | ------------------------------------------------ |
| **Flutter**         | UI framework                   | Cross-platform, rich UI toolkit                   |
| **flutter_bloc** (Cubit) | State management          | Simpler than full BLoC, clean separation of concerns |
| **Firebase Auth**   | Authentication                 | Managed auth with email/password support          |
| **Cloud Firestore** | Cloud database                 | Real-time streaming, NoSQL, per-user data isolation |
| **Hive**            | Local storage                  | Lightweight, fast, supports complex Map storage   |
| **Google Fonts**    | Typography (Outfit + Inter)    | Professional, modern font pairing                 |
| **connectivity_plus** | Network detection            | Enables offline/online sync decisions             |
| **uuid**            | ID generation                  | UUID v4 for offline-safe unique expense IDs       |
| **intl**            | Date formatting                | Locale-aware date display                         |

> **Note:** `hive_generator` is not used due to an analyzer conflict with `retrofit_generator`. All Hive serialization is done manually via `toHiveMap()` / `fromHiveMap()` methods.

---

## 📡 Offline-First Strategy

The core innovation of this project — expenses are **never blocked by network availability**:

```
User taps "Save"
       │
       ▼
 ┌─────────────┐
 │  Save to     │ ← Instant (< 1ms)
 │  Hive (local)│
 └──────┬──────┘
        │
        ▼
  UI shows success ✅  (form closes immediately)
        │
        ▼
 ┌─────────────┐
 │  Push to     │ ← Background (fire-and-forget)
 │  Firestore   │
 └──────┬──────┘
        │
   ┌────┴────┐
   │ Online? │
   ├── Yes ──┤→ Firestore saves → Delete from Hive ✅
   └── No  ──┘→ Stays in Hive as "pending" 🕐
                 → Syncs automatically when online
```

**Key design decisions:**
- **Hive as write-ahead log** — expenses are written locally first with `synced: false`
- **Fire-and-forget** — Firestore writes don't block the UI thread
- **UUID v4 for IDs** — generated client-side before any network call, ensuring uniqueness offline
- **Pending sync** — unsynced expenses persist in Hive and retry on reconnection

---

## 🧠 State Management

Using **Cubit** (from `flutter_bloc`) instead of full BLoC — simpler method calls instead of event classes:

| Cubit              | Scope       | States                                          |
| ------------------ | ----------- | ----------------------------------------------- |
| `AuthCubit`        | **Global**  | Initial, Loading, Authenticated, Unauthenticated, Error |
| `DashboardCubit`   | **Global**  | Initial, Loading, Loaded, Error                  |
| `BreakdownCubit`   | **Global**  | Initial, Loading, Loaded, Error                  |
| `AddExpenseCubit`  | **Scoped**  | Initial, Loading, Success, Error                 |

- **Global cubits** are created once in `main.dart` and available app-wide
- **Scoped cubits** (like `AddExpenseCubit`) are created per-screen and disposed automatically
- All states use `const` constructors and extend `Equatable` for efficient rebuilds

---

## 💉 Dependency Injection

All dependencies are wired in `main.dart` using `MultiRepositoryProvider` + `MultiBlocProvider`:

```
MultiRepositoryProvider
  ├── CategoryDataSource()
  ├── ExpenseDataSource()
  ├── AuthDataSource(categoryDataSource)
  ├── DashboardDataSource(expenseDataSource)
  └── BudgetDataSource()

MultiBlocProvider
  ├── AuthCubit(authDataSource)
  ├── DashboardCubit(dashboardDataSource, authDataSource)
  └── BreakdownCubit(expenseDS, categoryDS, authDS, budgetDS)
```

---

## 🗄️ Database Schema

### Firestore

```
users/{uid}/
├── categories/{categoryId}
│   ├── name: String
│   ├── colorHex: String          # e.g., "#F2726F"
│   ├── colorIndex: Number        # 0–11 (palette position)
│   ├── isCustom: Boolean
│   └── createdAt: Timestamp
├── expenses/{expenseId}
│   ├── amount: Number
│   ├── categoryId: String
│   ├── note: String?
│   ├── date: Timestamp
│   ├── createdAt: Timestamp
│   └── synced: Boolean (always true in Firestore)
└── budgets/{categoryId}
    ├── limit: Number
    └── month: String             # "YYYY-MM" format
```

### Hive (Local)

```
Box: 'pending_expenses'
└── Key: expense ID (UUID v4)
    └── Value: Map<String, dynamic>
        └── Same fields as Firestore but dates as ISO 8601 strings, synced = false
```

---

## 🎨 Design System

### Theme
- **Dark mode only** — background `#0F1117`, surface `#1A1D27`, accent `#6FA8DC`
- Zero-elevation flat design throughout
- Comprehensive `ThemeData` — most widgets need no manual styling

### Typography
- **Outfit** — headings, amounts, display text (bold, decorative)
- **Inter** — body text, labels (clean, readable)

### Category Palette
12 curated colors automatically assigned to categories:

```
🔴 Coral    🟠 Muted Orange   🟡 Soft Amber   🟢 Sage Green
💚 Mint     🩵 Teal           🔵 Sky Blue      💜 Soft Purple
🟣 Periwinkle  🩷 Dusty Pink  🤎 Warm Yellow   ⬜ Slate Teal
```

### Shared Widgets
- **`PrimaryButton`** — Full-width button with built-in loading spinner
- **`AppTextField`** — Themed text field with validation, icons, and focus management

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Dart `^3.11.1`
- A Firebase project with Auth + Firestore enabled

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/masroufi.git
   cd masroufi
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` to `android/app/`
   - Update `lib/firebase_options.dart` if needed

4. **Run the app**
   ```bash
   flutter run
   ```

### Static Analysis
```bash
flutter analyze lib/
# Should pass with 0 errors, 0 warnings, 0 infos
```

---

## 🚶 User Journey

```
App Launch → Splash Screen (auth check)
  ├── Not logged in → Login Screen ↔ Register Screen
  │                                      └── Seeds 7 default categories
  └── Logged in → Shell Screen (4-tab navigation)
                    ├── 📊 Dashboard    — Today/Week/Month summaries
                    ├── ➕ Add Expense  — Category + Amount + Note + Date
                    ├── 📋 Breakdown    — Per-category analysis + budgets
                    └── 📜 History      — Date-grouped expense list
```

---

## 📋 All User Actions

| #  | Action                    | Screen       | Description                                  |
| -- | ------------------------- | ------------ | -------------------------------------------- |
| 1  | Register                  | Register     | Create account + auto-seed 7 categories      |
| 2  | Sign in                   | Login        | Email/password authentication                |
| 3  | Sign out                  | Dashboard    | Logout and return to login                   |
| 4  | Add expense               | Add Expense  | Select category, enter amount/note/date      |
| 5  | Edit expense              | History      | Tap an expense to edit it                    |
| 6  | Delete expense            | History      | Swipe to delete with confirmation            |
| 7  | Add expense offline       | Add Expense  | Same flow — saves locally, syncs later       |
| 8  | View today's spending     | Dashboard    | Summary card with today's total              |
| 9  | View weekly spending      | Dashboard    | Summary card with this week's total          |
| 10 | View monthly spending     | Dashboard    | Summary card with this month's total         |
| 11 | View category breakdown   | Breakdown    | Per-category totals with progress bars       |
| 12 | Set category budget       | Breakdown    | Define monthly spending limit per category   |
| 13 | Edit/remove budget        | Breakdown    | Modify or remove an existing budget limit    |
| 14 | Pull to refresh           | All screens  | Refresh data on any main screen              |

---

## 📄 License

This project was built as a final project for a Flutter Bootcamp.
