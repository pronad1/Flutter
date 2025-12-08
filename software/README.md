# ReuseHub

A Flutter-based platform connecting donors and seekers to repurpose items across communities. ReuseHub promotes sustainability by making it easy to donate, request, and exchange gently used items.

## Overview

ReuseHub is a cross-platform mobile and web application built with Flutter and Firebase that facilitates the circular economy by connecting people who have items to donate with those who need them. The app streamlines the donation and request process while maintaining accountability through user profiles, ratings, and request limits.

## Key Features

- **Item Management**: Post items across 20+ categories with photos, descriptions, and condition levels
- **Smart Browsing**: Search and filter available items by category, condition, and availability
- **Request System**: Monthly request limits (4/month) with approval workflow and tracking
- **User Profiles**: Comprehensive profiles with donation history, request tracking, and ratings
- **Real-time Statistics**: Live counts of users, items, and availability status
- **Rating System**: Community-driven ratings for donors and seekers
- **AI Assistant**: Intelligent chatbot providing natural language help, statistics, and personalized information
- **Firebase Integration**: Authentication, Firestore database, and Cloud Storage for images

## Tech Stack

- **Framework**: Flutter (supports Android, iOS, Web, Windows, macOS, Linux)
- **Backend**: Firebase
  - Firebase Auth (Google Sign-In, email/password)
  - Cloud Firestore (real-time database)
  - Firebase Storage (image uploads)
- **State Management**: Provider pattern
- **UI/UX**: Material Design with custom animations and gradients

## Project Structure

```
lib/
├── src/
│   ├── models/          # Data models (User, Item, Request, etc.)
│   ├── services/        # Firebase services and business logic
│   ├── ui/
│   │   ├── screens/     # Main app screens
│   │   └── widgets/     # Reusable UI components
│   └── utils/           # Helper functions and constants
├── main.dart            # App entry point
└── firebase_options.dart # Firebase configuration
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Firebase account
- Node.js (for Firebase scripts)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/pronad1/Flutter.git
cd software
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Authentication (Email/Password, Google Sign-In)
   - Create Firestore database
   - Enable Firebase Storage
   - Download and add configuration files

4. Run the app:
```bash
flutter run
```

## Available Categories

Electronics, Computers & Laptops, Mobile Phones, Home & Furniture, Appliances, Books & Education, Sports & Fitness, Clothing & Fashion, Toys & Games, Kitchen & Dining, Tools & Hardware, Garden & Outdoor, Baby & Kids, Health & Beauty, Automotive, Pet Supplies, Office Supplies, Art & Crafts, Musical Instruments, and Other.

## Firebase Collections

- `items` - Donated items with details and availability
- `users` - User profiles (restricted access)
- `publicProfiles` - Public user data (readable by all)
- `requests` - Item requests with status tracking
- `reviews` - User ratings and reviews

## Scripts

- `scripts/create_public_profiles.js` - Initialize public profiles collection
- `scripts/migrate_public_profiles.js` - Sync user data to public profiles

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/auth_test.dart
```

## Building

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Deployment

Firebase Hosting (Web):
```bash
firebase deploy --only hosting
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/YourFeature`)
3. Commit changes (`git commit -m 'Add YourFeature'`)
4. Push to branch (`git push origin feature/YourFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Contact

For questions or support, please open an issue on GitHub.
