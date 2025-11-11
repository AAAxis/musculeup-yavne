# Firebase Google Sign-In Setup Guide

## Issue
Google Sign-In opens the account picker but doesn't complete authentication.

## Solution
You need to add your SHA-1 certificate fingerprint to Firebase Console.

---

## Step 1: Add SHA-1 Certificate to Firebase

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `muscule-up`
3. **Go to Project Settings** (gear icon in top left)
4. **Scroll down to "Your apps"** section
5. **Click on your Android app**: `com.muscleup.muscleup`
6. **Scroll down to "SHA certificate fingerprints"**
7. **Click "Add fingerprint"**
8. **Add the following SHA-1**:
   ```
   D0:D6:BE:B1:18:C9:F1:BA:B9:1D:E6:C3:47:41:5B:00:D5:AE:24:D7
   ```
9. **Click "Add fingerprint" again** and add SHA-256:
   ```
   F9:83:80:A8:5B:F2:74:C6:1D:A7:B7:4D:83:BB:99:B9:BD:F8:CE:84:05:54:B9:0A:8F:27:3B:5A:03:F3:4C:9B
   ```
10. **Click "Save"**

---

## Step 2: Enable Google Sign-In in Firebase

1. In Firebase Console, go to **Authentication** (in left sidebar)
2. Click on **Sign-in method** tab
3. Click on **Google** provider
4. **Toggle "Enable"** to ON
5. Set a **Project support email** (your email)
6. Click **Save**

---

## Step 3: Download Updated google-services.json

After adding the SHA certificates, Firebase will update your configuration:

1. Go back to **Project Settings**
2. Scroll to your Android app
3. Click **Download google-services.json**
4. Replace the existing file at:
   ```
   /Users/romanpochtman/Developer/muscleup/android/app/google-services.json
   ```

---

## Step 4: Restart Your App

After completing the above steps:

```bash
# Stop the running app
# Then run again
flutter run
```

---

## Troubleshooting

### If it still doesn't work:

1. **Check the package name** in Firebase matches exactly:
   - Firebase: `com.muscleup.muscleup`
   - Your app: Check `android/app/build.gradle.kts` → `applicationId`

2. **Verify Google Sign-In is enabled** in Firebase Authentication

3. **Clear app data** on your device/emulator:
   - Settings → Apps → MuscleUp → Storage → Clear Data

4. **Rebuild the app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## For Production Release

When you create a release build, you'll need to add your **release SHA-1** as well:

```bash
# Get release SHA-1 (after creating release keystore)
keytool -list -v -keystore /path/to/release.keystore -alias your-key-alias
```

Then add that SHA-1 to Firebase following the same steps above.

---

## Current Configuration

- **Package Name**: `com.muscleup.muscleup`
- **Debug SHA-1**: `D0:D6:BE:B1:18:C9:F1:BA:B9:1D:E6:C3:47:41:5B:00:D5:AE:24:D7`
- **Debug SHA-256**: `F9:83:80:A8:5B:F2:74:C6:1D:A7:B7:4D:83:BB:99:B9:BD:F8:CE:84:05:54:B9:0A:8F:27:3B:5A:03:F3:4C:9B`
- **Keystore**: `~/.android/debug.keystore` (default debug keystore)

