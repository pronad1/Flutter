Backfill ownerName on items

This small script populates the `ownerName` field on existing `items` documents by reading the corresponding `users/{ownerId}` document.

Prerequisites
- Node.js 18+ and npm
- A Google Cloud service account JSON with Firestore access, or run on a machine authenticated with `gcloud auth application-default login`.

Install

```powershell
cd tool
npm install firebase-admin
```

Run (PowerShell)

```powershell
# Using environment variable
$env:GOOGLE_APPLICATION_CREDENTIALS='C:\path\to\service-account.json'
node backfill_owner_names.js --project your-project-id

# Or pass service account directly
node backfill_owner_names.js --serviceAccount C:\path\to\service-account.json --project your-project-id
```

Safety
- The script only writes `ownerName` to items where `ownerName` is missing or empty.
- It batches writes and is idempotent.

If you'd like, I can instead add a Dart/Flutter in-app tool or a Cloud Function version.