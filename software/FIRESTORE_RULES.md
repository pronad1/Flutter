Recommended Firestore security rules for public profiles and reviews

When your app shows "Error: [cloud_firestore/permission-denied] Missing or insufficient permissions." it means your Firestore security rules currently block the client from reading the requested document.

Two safe options below. Choose the one that matches your privacy model.

1) Quick / permissive (makes user profile fields public)

Use this only for development or when you intentionally want profile fields to be publicly readable.

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Public read for user profiles (adjust to your privacy needs)
    match /users/{userId} {
      allow read: if true; // public read
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Reviews: anyone can read, only authenticated users can create reviews
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null
        && request.resource.data.reviewerId == request.auth.uid
        && request.resource.data.donorId is string;
      allow update, delete: if false;
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}

2) Safer option: require authentication to read profile (but allow items + public fallback)

If you don't want profile docs to be universally readable, require authenticated read access. The app already falls back to reading the donor's public `items` documents when profile reads are denied.

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null; // only authenticated clients
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null
        && request.resource.data.reviewerId == request.auth.uid
        && request.resource.data.donorId is string;
      allow update, delete: if false;
    }

    match /items/{itemId} {
      // Keep items publicly readable so seekers can browse the feed
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == resource.data.ownerId;
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}

How to deploy

Option A — Firebase Console (web)
- Go to https://console.firebase.google.com
- Select your project → Build → Firestore Database → Rules
- Replace rules with the chosen block above and Publish.

Option B — Firebase CLI
- Install & login: `npm install -g firebase-tools` then `firebase login`
- From your project folder: `firebase deploy --only firestore:rules`

Notes
- Tailor rules to your privacy policy. You can make only a subset of profile fields public by storing them in a separate `publicProfiles/{uid}` collection and allowing public reads only for that collection.
- The app includes a graceful fallback: when profile reads are denied, it will display donated items (if `items` are publicly readable). Use the safer rules with public `items` to keep browsing working while protecting private profile fields.
