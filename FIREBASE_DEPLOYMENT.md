# Firebase Deployment Guide

## Prerequisites
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login to Firebase: `firebase login`
3. Initialize project: `firebase init` (if not already done)

## Deploy Firestore Security Rules

To fix the "Missing or insufficient permissions" error, deploy the security rules:

```bash
# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Or deploy everything
firebase deploy
```

## Security Rules Overview

The `firestore.rules` file includes:

### Users Collection
- ✅ Users can read/write their own documents
- ✅ Users cannot manually modify ANIMA points (protected)
- ✅ Users cannot delete their profiles

### Sessions Collection  
- ✅ Authenticated users can create sessions they're part of
- ✅ Users can read/update sessions they're part of
- ✅ Sessions cannot be deleted

### Reports Collection (Future)
- ✅ Users can create reports
- ✅ Only admins can read reports
- ✅ Reports are immutable once created

## Testing Rules Locally

You can test rules locally using the Firebase Emulator:

```bash
# Start the emulator
firebase emulators:start

# Your app will connect to local emulator instead of production
```

## Verifying Deployment

After deployment, run the Firebase tests again in the app:
1. Open the app
2. Tap the hammer icon (🔨)
3. Run Firebase Tests
4. All 5 tests should now pass ✅

## Next Steps

Once rules are deployed, implement Cloud Functions for:
1. Session validation
2. ANIMA calculation with resonance multiplier
3. Abuse prevention and rate limiting