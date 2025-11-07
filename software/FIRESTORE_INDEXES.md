# Firestore Indexes

## Overview
This document explains the Firestore indexes used in this application and how to deploy them.

## Required Indexes

### Reviews Collection
**Purpose**: Enable querying reviews by donor with newest first ordering

**Index Configuration**:
- Collection: `reviews`
- Fields:
  - `donorId` (Ascending)
  - `createdAt` (Descending)

**Used By**: 
- `lib/src/services/review_service.dart` → `streamReviewsForDonor()`
- `lib/src/ui/screens/profile/public_profile_screen.dart` → Reviews & Ratings section

## Deploying Indexes

### Method 1: Firebase CLI (Recommended)
```bash
# Make sure you're in the project directory
cd d:\Languages\Flutter\Test

# Set the active Firebase project
firebase use reuse-hub-4b3f7

# Deploy the indexes
firebase deploy --only firestore:indexes
```

### Method 2: Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/project/reuse-hub-4b3f7/firestore/indexes)
2. Navigate to Firestore Database → Indexes
3. Click "Add Index"
4. Configure:
   - Collection ID: `reviews`
   - Field 1: `donorId` (Ascending)
   - Field 2: `createdAt` (Descending)
   - Query scope: Collection
5. Click "Create"

### Method 3: Click the Error Link
When you see the index error in the app, copy the URL from the error message and paste it in your browser. Firebase will automatically configure the index for you.

## Index Building Time
- **Small databases**: 1-2 minutes
- **Medium databases**: 5-10 minutes
- **Large databases**: Can take hours

Check index status at: https://console.firebase.google.com/project/reuse-hub-4b3f7/firestore/indexes

## Troubleshooting

### Error: "The query requires an index"
**Solution**: The index is still building. Wait a few minutes and refresh the app.

### Error: "FAILED_PRECONDITION"
**Solution**: Deploy the index using one of the methods above.

### Indexes Not Working
1. Check if indexes are deployed: `firebase firestore:indexes`
2. Verify Firebase project: `firebase use`
3. Redeploy: `firebase deploy --only firestore:indexes`
4. Check [Firebase Console](https://console.firebase.google.com/project/reuse-hub-4b3f7/firestore/indexes) for index status

## Files
- `firestore.indexes.json` - Index definitions
- `firebase.json` - Firebase configuration (includes index reference)
- `firestore.rules` - Security rules

## Auto-Recovery
The app includes automatic error handling:
- Shows user-friendly message when index is building
- Provides refresh button to check again
- Displays helpful instructions

---
Last Updated: November 7, 2025
