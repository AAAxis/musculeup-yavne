# Profile Setup Flow

## Overview

The app now includes a profile completion flow that ensures users fill out their details before accessing the main app.

## How It Works

### 1. **First Time Users**
When a user signs in with Google for the first time:
1. They authenticate with Google
2. The app checks Firestore for their profile
3. If no profile exists or profile is incomplete → **Profile Setup Screen**
4. After completing profile → **Main Dashboard**

### 2. **Returning Users**
When a user signs in again:
1. They authenticate with Google
2. The app checks Firestore for their profile
3. If profile is complete → **Main Dashboard** (directly)
4. If profile is incomplete → **Profile Setup Screen**

---

## Profile Setup Screen

### Required Fields:
1. **Full Name** - Pre-filled from Google Sign-In (editable)
2. **Gender** - Male/Female dropdown
3. **Birth Date** - Date picker
4. **Height (cm)** - Numeric input (100-250 cm)
5. **Weight (kg)** - Numeric input (30-300 kg)
6. **Coach Name** - Text input
7. **Coach Email** - Email validation

### Optional Fields:
- **Coach Phone** - Phone number input

---

## Firestore Structure

### Collection: `users`
### Document ID: User's email

```javascript
{
  "email": "user@example.com",
  "name": "John Doe",
  "photo_url": "https://...",
  "gender": "male",           // or "female"
  "birth_date": "1992-11-18", // YYYY-MM-DD format
  "height": 1.75,             // in meters (stored as cm / 100)
  "initial_weight": 70,       // in kg
  "coach_name": "Mark",
  "coach_email": "coach@example.com",
  "coach_phone": "+380548096606", // optional
  "role": "user",
  "status": "active",
  "created_at": Timestamp,
  "updated_at": Timestamp,
  "last_login": Timestamp
}
```

---

## Features

### ✅ Validation
- All required fields must be filled
- Email format validation for coach email
- Height range: 100-250 cm
- Weight range: 30-300 kg
- Birth date must be in the past

### ✅ User Experience
- Name pre-filled from Google account
- Date picker for birth date
- Dropdown for gender selection
- Clear error messages
- Loading state during save
- Can't skip profile setup

### ✅ Data Management
- Automatic Firestore integration
- Last login timestamp updated
- Profile completion check on every login
- Seamless navigation after completion

---

## Code Structure

```
lib/
├── data/
│   ├── models/
│   │   └── user_model.dart           # User data model
│   └── services/
│       ├── firebase_auth_service.dart # Auth + profile check
│       └── firestore_service.dart     # Firestore operations
└── presentation/
    └── profile_setup/
        └── profile_setup_screen.dart  # Profile form UI
```

---

## Testing

### Test New User Flow:
1. Sign in with a new Google account
2. Should see Profile Setup Screen
3. Fill all required fields
4. Click "Complete Profile"
5. Should navigate to Main Dashboard

### Test Returning User Flow:
1. Sign out
2. Sign in with same account
3. Should go directly to Main Dashboard

### Test Incomplete Profile:
1. Manually delete some fields from Firestore
2. Sign in again
3. Should see Profile Setup Screen

---

## Firebase Rules

Make sure your Firestore rules allow users to read/write their own documents:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{email} {
      allow read, write: if request.auth != null && request.auth.token.email == email;
    }
  }
}
```

---

## Future Enhancements

- [ ] Add profile editing screen
- [ ] Add profile picture upload
- [ ] Add more fitness metrics (body fat %, goals, etc.)
- [ ] Add onboarding wizard with multiple steps
- [ ] Add progress photos
- [ ] Add measurement tracking

