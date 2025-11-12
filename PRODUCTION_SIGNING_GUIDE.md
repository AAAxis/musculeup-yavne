# Production Signing Guide for MuscleUp

## Step 1: Create Production Keystore

Run this command and follow the prompts:

```bash
keytool -genkey -v -keystore android/app/muscleup-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias muscleup-key
```

You'll be prompted for:
1. **Keystore password**: Choose a strong password (remember this!)
2. **Key password**: Can be the same as keystore password
3. **First and last name**: Your name or company name
4. **Organizational unit**: Your department/team (optional)
5. **Organization**: Your company name
6. **City/Locality**: Your city
7. **State/Province**: Your state
8. **Country code**: Two-letter country code (e.g., US, UK, etc.)

## Step 2: Create key.properties file

Create `android/key.properties` with:
```
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=muscleup-key
storeFile=muscleup-release-key.jks
```

## Step 3: Configure build.gradle

The build.gradle will be automatically configured to use the keystore.

## Step 4: Get Production SHA Fingerprints

After creating the keystore, run:
```bash
keytool -list -v -keystore android/app/muscleup-release-key.jks -alias muscleup-key
```

## Step 5: Add SHA Fingerprints to Firebase

Add the production SHA-1 and SHA-256 to your Firebase project settings.

## Step 6: Build Production APK/AAB

```bash
# For APK
flutter build apk --release

# For App Bundle (recommended for Play Store)
flutter build appbundle --release
```

## Important Notes:

- **BACKUP YOUR KEYSTORE**: Store it securely! If you lose it, you cannot update your app on Play Store
- **Keep passwords safe**: Store them in a password manager
- **Never commit keystore to version control**: Add to .gitignore
