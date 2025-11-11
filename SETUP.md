# Setup Instructions

## Prerequisites

Make sure you have Flutter SDK installed. If not, follow the official guide:
https://docs.flutter.dev/get-started/install

## Installation Steps

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Verify Flutter installation:**
   ```bash
   flutter doctor
   ```

3. **Run the app:**
   ```bash
   # For iOS (requires macOS)
   flutter run -d ios
   
   # For Android
   flutter run -d android
   
   # For Chrome (web)
   flutter run -d chrome
   ```

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── di/
│   │   └── service_locator.dart      # Dependency injection setup
│   └── models/
│       ├── email.dart                # Email validation model
│       └── password.dart             # Password validation model
├── data/
│   └── repositories/
│       └── auth_repository.dart      # Authentication repository
└── presentation/
    └── login/
        ├── bloc/
        │   ├── login_bloc.dart       # BLoC for login logic
        │   ├── login_event.dart      # Login events
        │   └── login_state.dart      # Login state
        ├── widgets/
        │   ├── email_input.dart      # Email input field
        │   ├── password_input.dart   # Password input field
        │   └── login_button.dart     # Login button
        └── login_screen.dart         # Login screen UI
```

## Features Implemented

✅ Modern Material Design 3 UI
✅ BLoC state management pattern
✅ Form validation with Formz
✅ Email and password validation
✅ Password visibility toggle
✅ Loading states
✅ Error handling with snackbars
✅ Dependency injection with GetIt
✅ Clean architecture structure

## Next Steps

The authentication repository (`lib/data/repositories/auth_repository.dart`) currently simulates a login. You'll need to:

1. Add your backend API endpoint
2. Implement actual HTTP requests
3. Handle JWT tokens or session management
4. Add secure storage for credentials
5. Implement logout functionality
6. Add sign-up screen
7. Add forgot password flow

## Testing the Login

Currently, any email/password combination will work after a 2-second delay. The form validates:
- Email must be a valid email format
- Password must be at least 6 characters

Try it out with:
- Email: `test@example.com`
- Password: `password123`

