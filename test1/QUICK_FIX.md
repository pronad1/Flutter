# 🚨 QUICK FIX - Profile Not Loading

## What's Happening Right Now

You're seeing "No publicly readable items found for this donor" because:

1. ❌ **Firestore rules are NOT deployed** → Can't read `publicProfiles/{userId}`
2. ❌ **Fallback tries to show donated items** → User has no items donated yet
3. ✅ **Help dialog shows correctly** → Tells you to deploy rules

## 🔧 IMMEDIATE FIX (5 minutes)

### Step 1: Deploy Firestore Rules (REQUIRED!)

1. Go to: https://console.firebase.google.com
2. Select your project
3. Click: **Build** → **Firestore Database** → **Rules** tab
4. **Copy this entire block** and paste it (replace everything):

```firestore
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

    // --- publicProfiles (NEW - publicly readable) ---
    match /publicProfiles/{userId} {
      allow read: if true; // ← THIS ALLOWS ANYONE TO READ PUBLIC PROFILES
      allow create, update: if isSelf(userId);
      allow delete: if false;
    }

    // --- users (keep private) ---
    match /users/{userId} {
      allow create: if isSelf(userId);
      allow read, update: if isSelf(userId) || isAdmin();
      allow delete: if isAdmin();
    }

    // --- items ---
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

    // --- reviews (NEW) ---
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if isSignedIn()
        && request.resource.data.reviewerId == request.auth.uid
        && request.resource.data.donorId is string
        && request.resource.data.rating is int
        && request.resource.data.rating >= 1
        && request.resource.data.rating <= 5;
      allow update, delete: if false;
    }

    // --- requests ---
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
```

5. Click **Publish** button (top right)
6. Wait for "Rules published successfully" message

### Step 2: Create publicProfiles for Your Test User

**Option A: Quick Test with New User** (Recommended)
```powershell
# Just create a new test account in your app
# The signup flow now automatically creates publicProfiles
```

**Option B: Update Existing User**
1. Log in as the user
2. Go to **Edit Profile**
3. Change anything (name, bio, photo)
4. Click **Save**
5. Now their `publicProfiles/{uid}` document exists!

### Step 3: Test Again

1. Restart your app: `flutter run`
2. Tap any product
3. You should now see the donor's profile with:
   - ✅ Name, photo, bio
   - ✅ Reviews section
   - ✅ Email button
   - ✅ Donated items

## 🔍 How to Verify Rules Are Deployed

Go to Firebase Console → Firestore Database → Rules tab

You should see `match /publicProfiles/{userId}` with `allow read: if true;`

## 🐛 Still Not Working?

### Check 1: Is the publicProfiles document created?

Go to Firebase Console → Firestore → Data tab → Look for `publicProfiles` collection

- **If it exists**: Rules are working! ✅
- **If it doesn't exist**: User needs to update their profile (Step 2 above)

### Check 2: View Flutter Console Logs

```powershell
flutter run
# Watch for error messages when you tap a product
```

Look for:
- ✅ Good: "Successfully read publicProfiles/..."
- ❌ Bad: "permission-denied" → Rules not deployed correctly
- ❌ Bad: "document does not exist" → Need to create publicProfiles (Step 2)

### Check 3: Verify User ID

When you tap a product, the app tries to read `publicProfiles/{ownerId}`.

Make sure:
1. The product has an `ownerId` field
2. That `ownerId` matches a real user's UID
3. That user has updated their profile (to create publicProfiles)

## 📝 Technical Explanation

Your code flow:
1. Tap product → Navigate to `PublicProfileScreen(userId: ownerId)`
2. Try to read `publicProfiles/{userId}` ← **REQUIRES RULES**
3. If denied, try `users/{userId}` ← Requires you to be owner/admin
4. If denied, show donated items ← Shows the screen you're seeing now

The fix: Deploy rules (Step 1) → Create publicProfiles (Step 2) → Test (Step 3)

---

## ⚡ FASTEST PATH TO SUCCESS

```powershell
# 1. Deploy rules (copy-paste from above into Firebase Console)
# 2. Create new test user in app (automatic publicProfiles creation)
# 3. Test: tap product → see profile!
```

**Time: 5 minutes total**

---
**Last Updated**: October 26, 2025
