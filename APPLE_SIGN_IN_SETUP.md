# Apple Sign In Setup Guide

## Prerequisites

1. **Apple Developer Account** - You need an active Apple Developer account
2. **Xcode** - Latest version installed
3. **Firebase Console** - Apple Sign In must be enabled in Firebase Authentication

## Steps to Enable Apple Sign In

### 1. Enable Apple Sign In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** > **Sign-in method**
4. Click on **Apple** provider
5. Enable it and save

### 2. Configure Apple Sign In in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Sign in with Apple** capability
6. Make sure the entitlements file (`Runner.entitlements`) is properly linked

### 3. Configure in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your **App ID**
4. Enable **Sign in with Apple** capability
5. Save the changes

### 4. Update Firebase Configuration

The `Runner.entitlements` file has been created with the Sign in with Apple capability. Make sure it's properly configured in Xcode.

### 5. Install Dependencies

Run the following command to install the new package:

```bash
flutter pub get
```

### 6. Test

1. Run the app on a physical iOS device (Apple Sign In doesn't work in simulator)
2. Tap the "המשך עם Apple" (Continue with Apple) button
3. Complete the Apple Sign In flow

## Notes

- Apple Sign In only works on **physical iOS devices**, not in the iOS Simulator
- The first time a user signs in, Apple may provide their name and email
- On subsequent sign-ins, Apple may only provide the user ID (for privacy)
- The app handles both cases gracefully

## Troubleshooting

If you encounter issues:

1. **"Sign in with Apple is not available"**
   - Make sure you're testing on a physical device
   - Verify the capability is enabled in Xcode
   - Check that the entitlements file is properly linked

2. **"Invalid client" error**
   - Verify Apple Sign In is enabled in Firebase Console
   - Check that your bundle ID matches in Firebase and Xcode

3. **Build errors**
   - Run `flutter clean` and `flutter pub get`
   - In Xcode, clean build folder (Cmd+Shift+K)
   - Rebuild the project

