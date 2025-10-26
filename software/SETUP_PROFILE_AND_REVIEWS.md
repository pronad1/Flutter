# Donor Profile & Review System - Setup Guide

## What This Feature Does
- ✅ Tap any product → view the donor's public profile
- ✅ See donor name, photo, bio
- ✅ View reviews and average rating for that donor
- ✅ Submit reviews (1-5 stars + text)
- ✅ Send email to donor (if email is in profile)
- ✅ View donated items by that donor

## Files Changed/Added

### New Files
- `lib/src/services/review_service.dart` - Manages review CRUD operations
- `lib/src/ui/screens/profile/public_profile_screen.dart` - Public donor profile UI
- `scripts/migrate_public_profiles.js` - Migration script for existing users
- `FIRESTORE_RULES.md` - Firestore security rules documentation
- `SETUP_PROFILE_AND_REVIEWS.md` - This file

### Modified Files
- `lib/src/ui/screens/home_screen.dart` - Added tap navigation to donor profile
- `lib/src/ui/screens/edit_profile_screen.dart` - Writes to publicProfiles on save
- `lib/src/services/auth_service.dart` - Creates publicProfiles on signup
- `pubspec.yaml` - Added url_launcher dependency

## Firestore Collections

### 1. publicProfiles/{userId}
**Purpose**: Public-facing minimal profile (readable by anyone)

**Fields**:
- `name` (string) - Donor's display name
- `bio` (string) - Short bio
- `photoUrl` (string) - Profile photo URL
- `email` (string) - Email (optional, only if you want it public)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

### 2. reviews/{reviewId}
**Purpose**: Reviews for donors

**Fields**:
- `donorId` (string) - User ID being reviewed
- `reviewerId` (string) - User ID who left the review
- `reviewerName` (string) - Name of reviewer
- `rating` (int) - 1 to 5
- `text` (string) - Review text (optional)
- `createdAt` (timestamp)

### 3. users/{userId}
**Purpose**: Private full user profile (only readable by owner/admin)

**Fields**: (existing) email, role, name, mobile, approved, etc.

## Required Firestore Security Rules

### Option 1: Recommended (safer - uses publicProfiles)
Copy and paste this into Firebase Console → Firestore → Rules:

\`\`\`firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // --- helpers ---
    function isSignedIn() {
      return request.auth != null;
    }
    function isSelf(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    function isAdmin() {
      return isSignedIn()
        && exists(/databases/$(database)/documents/users/$(request.auth.uid))
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }

    // --- publicProfiles (publicly readable minimal profile) ---
    match /publicProfiles/{userId} {
      allow read: if true; // public read
      allow create, update: if isSelf(userId);
      allow delete: if false;
    }

    // --- users (private full profile) ---
    match /users/{userId} {
      allow create: if isSelf(userId);
      allow read, update: if isSelf(userId) || isAdmin();
      allow delete: if isAdmin();
    }

    // --- items (posted by donors) ---
    match /items/{itemId} {
      allow read: if true;
      allow create: if isSignedIn() &&
        request.resource.data.ownerId == request.auth.uid;
      allow update: if (
        isSignedIn() &&
        resource.data.ownerId == request.auth.uid &&
        request.resource.data.ownerId == resource.data.ownerId
      ) || isAdmin();
      allow delete: if (
        isSignedIn() && resource.data.ownerId == request.auth.uid
      ) || isAdmin();
    }

    // --- requests (seeker -> donor) ---
    match /requests/{requestId} {
      allow read: if isSignedIn() && (
        resource.data.ownerId == request.auth.uid ||
        resource.data.seekerId == request.auth.uid ||
        isAdmin()
      );
      allow create: if isSignedIn() &&
        request.resource.data.seekerId == request.auth.uid;
      allow update: if (
        isSignedIn() &&
        resource.data.ownerId == request.auth.uid &&
        request.resource.data.ownerId == resource.data.ownerId &&
        request.resource.data.seekerId == resource.data.seekerId &&
        request.resource.data.itemId  == resource.data.itemId &&
        request.resource.data.keys().hasOnly(
          ['itemId','ownerId','seekerId','status','createdAt','updatedAt']
        )
      ) || isAdmin();
      allow delete: if (
        isSignedIn() && resource.data.ownerId == request.auth.uid
      ) || isAdmin();
    }

    // --- reviews (publicly readable, authenticated create with validation) ---
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if isSignedIn()
        && request.resource.data.reviewerId == request.auth.uid
        && request.resource.data.donorId is string
        && request.resource.data.rating is int
        && request.resource.data.rating >= 1
        && request.resource.data.rating <= 5
        && request.resource.data.reviewerName is string
        && (request.resource.data.text is string || request.resource.data.text == null);
      allow update, delete: if false;
    }

    // --- chats ---
    match /chats/{chatId} {
      allow read, write: if isAdmin() ||
        (isSignedIn() && (
          (request.resource.data.members != null && request.auth.uid in request.resource.data.members) ||
          (resource.data.members != null && request.auth.uid in resource.data.members)
        ));

      match /messages/{messageId} {
        allow read, write: if isAdmin() ||
          (isSignedIn() &&
           request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.members);
      }
    }

    // --- default deny ---
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
\`\`\`

### Option 2: Quick Fix (simpler but less private)
If you want to skip publicProfiles and make users/{uid} public:

\`\`\`firestore
match /users/{userId} {
  allow read: if true; // public read
  allow write: if request.auth != null && request.auth.uid == userId;
}
\`\`\`

**Note**: This exposes ALL fields in users/{uid} publicly. Only use for development/testing.

## Setup Steps

### Step 1: Deploy Firestore Rules
1. Go to https://console.firebase.google.com
2. Select your project → Build → Firestore Database → Rules
3. Copy the rules from **Option 1** above
4. Click **Publish**

### Step 2: Migrate Existing Users (if you have existing users)
For existing users who signed up before this update, run the migration script to create their publicProfiles:

\`\`\`powershell
# Install dependencies (one time)
cd 'd:\\Languages\\Fllutter\\test1'
npm init -y
npm install firebase-admin

# Set your service account JSON path
$env:GOOGLE_APPLICATION_CREDENTIALS='C:\\path\\to\\your\\service-account.json'

# Run migration
node scripts\\migrate_public_profiles.js
\`\`\`

**Where to get service account JSON**:
1. Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Save the JSON file securely

### Step 3: Test the Feature
1. Run the app: `flutter run`
2. Sign up a new user (this will create publicProfiles automatically)
3. Go to Home screen, tap any product
4. You should see the donor's profile with:
   - Name, photo, bio
   - Reviews (if any)
   - Submit review form
   - Email button (if email is in profile)
   - View donated items button

### Step 4: (Optional) Update Existing User Profiles
For any existing users, have them:
1. Log in
2. Go to Edit Profile
3. Update their name/bio/photo
4. Click "Save Changes"

This will automatically create/update their publicProfiles document.

## How It Works

### Data Flow
1. **User signs up** → `auth_service.dart` creates:
   - `users/{uid}` (full profile, private)
   - `publicProfiles/{uid}` (minimal public fields)

2. **User edits profile** → `edit_profile_screen.dart` updates:
   - `users/{uid}` (full profile)
   - `publicProfiles/{uid}` (public fields only)

3. **User taps product** → `home_screen.dart` navigates to:
   - `PublicProfileScreen` with ownerId

4. **Profile screen loads** → `public_profile_screen.dart`:
   - Tries `publicProfiles/{userId}` first (preferred)
   - Falls back to `users/{userId}` (if authenticated and allowed)
   - Falls back to showing donated items (if both blocked)

5. **User submits review** → `review_service.dart`:
   - Validates user is logged in
   - Creates `reviews/{reviewId}` with rating, text, reviewerId
   - Firestore rules validate rating is 1-5 and reviewerId matches auth.uid

### Security
- `publicProfiles/{uid}` → public read, owner-only write
- `users/{uid}` → owner/admin only
- `reviews/{uid}` → public read, authenticated write with validation
- `items/{uid}` → public read, owner/admin write

## Troubleshooting

### "Donor profile (limited)" - No items found
**Cause**: User has no publicProfiles and users/{uid} is blocked by rules.

**Fix**:
1. Deploy the rules (Step 1 above)
2. Either:
   - Run migration script (Step 2), OR
   - Have the user update their profile (Step 4)

### "Permission denied" error
**Cause**: Firestore rules not deployed.

**Fix**: Deploy rules from Step 1.

### Email button not showing
**Cause**: Email field missing in publicProfiles.

**Fix**: Include email when creating publicProfiles (already done in auth_service.dart), or have user update their profile.

### Reviews not loading
**Cause**: Reviews rules not deployed.

**Fix**: Make sure the `reviews` match block is in your Firestore rules (Step 1).

## Next Steps / Enhancements
- [ ] Add pagination for reviews (currently loads all)
- [ ] Add duplicate-check for reviews (prevent same user from reviewing multiple times)
- [ ] Add abuse reporting for reviews
- [ ] Add notification to donor when they receive a review
- [ ] Add average rating to item cards on home screen
- [ ] Add search/filter for users by rating
- [ ] Add widget tests for navigation and review submission

## Support
If you encounter issues:
1. Check Flutter logs: `flutter run` in terminal
2. Check Firebase Console → Firestore → Logs
3. Verify rules are published correctly
4. Test with a fresh user signup to ensure publicProfiles is created

---
**Last Updated**: October 26, 2025
