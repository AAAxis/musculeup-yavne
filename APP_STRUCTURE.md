# MuscleUp App Structure

## 🎯 Navigation Structure

The app now has a bottom navigation bar with 5 main sections:

### 1. **Home** 🏠
- User greeting with profile picture
- Quick stats (Workouts, Streak)
- Today's progress tracking (Calories, Water, Active Time)
- Quick action buttons (Start Workout, Log Meal)

### 2. **Boost** ⚡
- Supplements and nutrition tips
- Categories:
  - Pre-Workout (Energy and focus boosters)
  - Protein (Muscle building supplements)
  - Recovery (Post-workout recovery aids)
  - Vitamins (Daily health supplements)

### 3. **Meals** 🍽️
- Meal plans and recipes
- Categories:
  - Breakfast (12 recipes)
  - Lunch (18 recipes)
  - Dinner (20 recipes)
  - Snacks (15 recipes)

### 4. **Train** 💪
- Training programs and workouts
- Programs:
  - Strength Training (45-60 min, Intermediate)
  - Cardio Blast (30-45 min, All Levels)
  - Flexibility & Yoga (20-30 min, Beginner)
  - HIIT (20-30 min, Advanced)

### 5. **Log** 📝
- Training log and workout history
- Track progress over time
- Currently shows empty state with "Log Workout" button

---

## 🎨 Features

### AppBar
- Dynamic title based on current screen
- Notifications icon
- Settings menu with:
  - Profile
  - Settings
  - Help & Support
  - Sign Out

### Bottom Navigation
- Material Design 3 NavigationBar
- Outlined icons when inactive
- Filled icons when active
- Smooth transitions between screens

---

## 📱 Screens Overview

```
lib/presentation/
├── auth/
│   ├── login_screen.dart          # Google Sign-In
│   └── bloc/                      # Authentication BLoC
├── navigation/
│   └── main_navigation.dart       # Bottom nav + AppBar
├── home/
│   └── home_screen.dart           # Dashboard with stats
├── boost/
│   └── boost_screen.dart          # Supplements categories
├── meals/
│   └── meals_screen.dart          # Recipe categories
├── workouts/
│   └── workouts_screen.dart       # Training programs
└── log/
    └── log_screen.dart            # Workout history
```

---

## 🔄 User Flow

1. **Login** → Google Sign-In
2. **Home** → View stats and quick actions
3. **Navigate** → Use bottom nav to explore sections
4. **Settings** → Access via AppBar menu
5. **Sign Out** → Return to login screen

---

## 🎯 Next Steps (TODO)

- [ ] Implement actual data storage (Firebase Firestore)
- [ ] Add workout logging functionality
- [ ] Implement recipe details pages
- [ ] Add supplement information pages
- [ ] Create workout video/instruction pages
- [ ] Add progress charts and analytics
- [ ] Implement notifications
- [ ] Add profile editing
- [ ] Create settings page
- [ ] Add onboarding flow for new users

---

## 🎨 Design System

- **Primary Color**: Purple (#6C63FF)
- **Card Elevation**: 1-2
- **Border Radius**: 12-16px
- **Spacing**: 8, 12, 16, 24, 32, 48px
- **Icons**: Material Design outlined/filled
- **Typography**: Material Design 3 text styles

---

## 🔐 Authentication

- Google Sign-In only
- Firebase Authentication
- Automatic session management
- Sign out from settings menu

