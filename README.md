# 🌱 ReuseHub - Donation & Reuse Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-4.0.0-FFCA28?logo=firebase)](https://firebase.google.com)
[![Supabase](https://img.shields.io/badge/Supabase-2.10.1-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-Private-red)](LICENSE)

**ReuseHub** is a comprehensive Flutter-based mobile application that connects donors with seekers to facilitate the donation and reuse of items. The platform promotes sustainability by enabling users to give away items they no longer need to those who can benefit from them.
---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Security](#-security)
- [Testing](#-testing)
- [Contributing](#-contributing)

---


## ✨ Features

### 🔐 Authentication & User Management
- **Email/Password Authentication** via Firebase Auth
- **Role-based System**: Users can be Donors, Seekers, or both
- **Admin Approval System**: New users require admin approval before full access
- **Profile Management**: Users can edit profiles with photos, bio, and contact info
- **Public Profiles**: View donor/seeker profiles with ratings and reviews

### 📦 Item Management
- **Post Items**: Donors can list items with images, descriptions, categories, and pickup addresses
- **Browse Items**: Public feed of all available items
- **Item Details**: View comprehensive item information with owner details
- **Edit/Delete Items**: Donors can manage their posted items
- **Category & Condition Filters**: Organize items by type and condition (New/Good/Used)
- **Search Functionality**: Find items by title, description, or category

### 🤝 Request System
- **Send Requests**: Seekers can request items from donors
- **Request Management**: Donors can approve/reject requests
- **Status Tracking**: Monitor request status (Pending/Approved/Rejected)
- **Notifications**: Real-time updates on request status

### 💬 Messaging
- **In-app Chat**: Private messaging between donors and seekers
- **Real-time Communication**: Powered by Firebase Firestore
- **Chat History**: Persistent conversation history

### ⭐ Review & Rating System
- **Rate Donors**: Seekers can leave reviews and ratings (1-5 stars)
- **Public Reviews**: Display on donor profiles
- **Rating Summary**: Average rating calculation with review count
- **Immutable Reviews**: Reviews cannot be edited or deleted (prevents abuse)

### 🤖 AI Assistant
- **ReuseHub Assistant**: Draggable chatbot with 100+ intelligent responses
- **Context-aware Help**: Answers questions about app features
- **Quick Actions**: Pre-defined buttons for common queries
- **Always Available**: Accessible from all main screens

### 🎨 User Interface
- **Material Design 3**: Modern, clean UI following Material guidelines
- **Custom Fonts**: Poppins and Google Fonts integration
- **Responsive Design**: Optimized for various screen sizes
- **Bottom Navigation**: Easy access to Home, Search, Profile
- **Splash Screen**: Branded startup experience

---

## 🏗️ Architecture

ReuseHub follows a **clean architecture** pattern with clear separation of concerns:

```
lib/
├── src/
│   ├── config/          # App configuration (routes, constants)
│   ├── models/          # Data models (User, Item, Message, Request)
│   ├── services/        # Business logic & Firebase/Supabase interactions
│   ├── providers/       # State management (Provider pattern)
│   ├── ui/              # User interface components
│   │   ├── screens/     # Full-page screens
│   │   └── widgets/     # Reusable UI components
│   └── utils/           # Helper functions & utilities
├── firebase_options.dart
└── main.dart            # App entry point
```

### Design Patterns
- **Provider Pattern**: State management across the app
- **Service Layer**: Abstraction of backend operations
- **Repository Pattern**: Data access through services
- **Singleton Pattern**: Firebase/Supabase instances

---

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.8.1+** - Cross-platform mobile framework
- **Dart SDK** - Programming language

### Backend Services
- **Firebase**
  - Firebase Auth (Authentication)
  - Cloud Firestore (Database)
  - Firebase Storage (Legacy image storage)
- **Supabase**
  - Supabase Storage (Primary image storage)
  - Real-time subscriptions

### Key Dependencies
```yaml
name: software
description: "A new Flutter project."
version: 1.0.0+1

environment:
  sdk: ^3.8.1

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  firebase_core: ^4.0.0        # Upgraded from 2.31.0
  firebase_auth: ^6.0.0        # Upgraded from 4.17.6
  cloud_firestore: ^6.0.0
  firebase_storage: ^13.0.0
  provider: ^6.1.2
  uuid: ^4.3.3
  cached_network_image: ^3.3.1
  google_fonts: ^6.2.0
  intl: ^0.20.2
  flutter_svg: ^2.2.0
  http: ^1.4.0
  fluttertoast: ^8.2.12         # Keep latest
  pin_code_fields: ^8.0.1
  shared_preferences: ^2.5.3
  supabase_flutter: ^2.10.1
  image_picker: ^1.2.0
  path: ^1.9.0
  mime: ^2.0.0
  url_launcher: ^6.1.7


dev_dependencies:
  flutter_test:
    sdk: flutter


  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/data/


  fonts:
    - family: poppins
      fonts:
        - asset: fonts/Poppins-Regular.ttf

```

---

## 📁 Project Structure

```
software/
├── android/              # Android native code
├── ios/                  # iOS native code
├── lib/
│   ├── src/
│   │   ├── config/
│   │   │   └── routes.dart                    # Route definitions
│   │   ├── models/
│   │   │   ├── item.dart                      # Item model
│   │   │   ├── message.dart                   # Message model
│   │   │   ├── request.dart                   # Request model
│   │   │   └── user.dart                      # User model
│   │   ├── services/
│   │   │   ├── auth_service.dart              # Authentication logic
│   │   │   ├── item_service.dart              # Item CRUD operations
│   │   │   ├── messaging_service.dart         # Chat functionality
│   │   │   ├── request_service.dart           # Request handling
│   │   │   ├── review_service.dart            # Review system
│   │   │   ├── storage_service.dart           # Firebase Storage
│   │   │   └── supabase_image_service.dart    # Supabase Storage
│   │   └── ui/
│   │       ├── screens/
│   │       │   ├── auth/                      # Login/Signup screens
│   │       │   ├── role/                      # Donor/Seeker dashboards
│   │       │   ├── profile/                   # Profile screens
│   │       │   ├── admin/                     # Admin approval
│   │       │   ├── home_screen.dart           # Main feed
│   │       │   ├── search_screen.dart         # Search interface
│   │       │   ├── item_detail_screen.dart    # Item details
│   │       │   ├── create_item_screen.dart    # Post new item
│   │       │   └── messaging_screen.dart      # Chat interface
│   │       └── widgets/
│   │           ├── app_bottom_nav.dart        # Bottom navigation
│   │           └── chatbot/                   # AI assistant widget
│   ├── firebase_options.dart                  # Firebase config
│   └── main.dart                              # App entry point
├── assets/
│   └── images/                                # Image assets
├── fonts/                                     # Custom fonts
├── scripts/                                   # Utility scripts
│   ├── create_public_profiles.js              # Profile migration
│   └── migrate_public_profiles.js             # Data migration
├── test/                                      # Unit tests
├── firestore.rules                            # Security rules
├── pubspec.yaml                               # Dependencies
└── README.md                                  # This file
```

---

## 🚀 Installation

### Prerequisites
- **Flutter SDK** (3.8.1 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (3.8.1+)
- **Android Studio** / **Xcode** (for mobile development)
- **Firebase Account** - [Create Firebase Project](https://console.firebase.google.com/)
- **Supabase Account** - [Create Supabase Project](https://supabase.com/)

### Step 1: Clone Repository
```bash
git clone https://github.com/pronad1/Flutter.git
cd Flutter/software
```

### Step 2: Install Dependencies
```powershell
flutter pub get
```

### Step 3: Set Up Firebase
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android/iOS apps to your Firebase project
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place configuration files in appropriate directories:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
5. Run Firebase CLI to generate `firebase_options.dart`:
```powershell
flutterfire configure
```

### Step 4: Set Up Supabase
1. Create a Supabase project at [Supabase Dashboard](https://supabase.com/dashboard)
2. Create storage buckets:
   - `profile-photos` (Public)
   - `item-images` (Public)
3. Update Supabase credentials in `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### Step 5: Deploy Firestore Security Rules
```powershell
firebase deploy --only firestore:rules
```

### Step 6: Run the App
```powershell
flutter run
```

---

## ⚙️ Configuration

### Firebase Configuration
The app uses Firebase for authentication and database. Configuration is stored in:
- `firebase_options.dart` (auto-generated)
- `firebase.json` (deployment config)
- `firestore.rules` (security rules)

### Environment Variables
For production, consider using environment variables for sensitive data:
1. Create `.env` file (add to `.gitignore`)
2. Use `flutter_dotenv` package to load variables

### Admin Setup
To grant admin privileges to a user:
1. Update Firestore manually:
```javascript
db.collection('users').doc('USER_ID').update({
  isAdmin: true
});
```
2. Or hardcode admin email in `routes.dart`:
```dart
static const String _hardcodedAdminEmail = 'your-admin@example.com';
```

---

## 📖 Usage

### For Donors
1. **Sign Up** → Choose "Donor" role → Wait for admin approval
2. **Post Items** → Tap "+" → Fill item details → Upload photo
3. **Manage Requests** → View requests on donor dashboard → Approve/Reject
4. **Chat with Seekers** → Communicate after request approval

### For Seekers
1. **Sign Up** → Choose "Seeker" role → Wait for admin approval
2. **Browse Items** → Home screen shows available items
3. **Request Items** → Tap item → Tap "Request" button
4. **Track Requests** → View status on seeker dashboard
5. **Rate Donors** → Leave reviews after receiving items

### For Admins
1. **Access Admin Panel** → Navigate to `/admin-approval` route
2. **Review New Users** → Approve/reject pending users
3. **Moderate Content** → Manage items, reviews, and reports

---

## 🔒 Security

### Firestore Security Rules
The app implements comprehensive security rules covering:
- **User Authentication**: All operations require authentication
- **Role-based Access**: Donors, Seekers, Admins have different permissions
- **Data Validation**: Input validation for ratings, reviews, requests
- **Privacy Protection**: Users can only access their own data
- **Immutable Reviews**: Prevents review manipulation
- **Admin Controls**: Special admin privileges for moderation

Key security features:
```javascript
// Only authenticated users can create items
allow create: if isSignedIn() && request.resource.data.ownerId == request.auth.uid;

// Only item owner or admin can update
allow update: if (isSelf(resource.data.ownerId)) || isAdmin();

// Reviews are immutable
allow update, delete: if false;
```

### Best Practices
- ✅ Never expose API keys in version control
- ✅ Use environment variables for sensitive data
- ✅ Implement rate limiting on Firebase
- ✅ Enable Firebase App Check
- ✅ Regular security audits of Firestore rules
- ✅ Monitor Firebase usage for anomalies

---

## 🧪 Testing

### Run Unit Tests
```powershell
flutter test
```

### Test Files
- `test/auth_test.dart` - Authentication service tests
- `test/item_test.dart` - Item service tests
- `test/messaging_test.dart` - Messaging service tests
- `test/widget_test.dart` - Widget tests

### Manual Testing Checklist
- [ ] User registration and login
- [ ] Admin approval workflow
- [ ] Item posting and editing
- [ ] Request creation and approval
- [ ] Messaging between users
- [ ] Review submission
- [ ] Profile editing
- [ ] Image upload/delete
- [ ] Search functionality
- [ ] Chatbot interactions

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Write unit tests for new features

---

## 📝 License

This project is **private** and not licensed for public use. All rights reserved.

---

## 👥 Authors

- **Pronad** - [GitHub](https://github.com/pronad1)

---

## 📞 Support

For questions or support:
- **Email**: ug2102049@cse.pstu.ac.bd
- **Issues**: [GitHub Issues](https://github.com/pronad1/Flutter/issues)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Supabase for storage solutions
- Material Design for UI inspiration
- Open source community for packages and tools

---

## 📊 Project Status

**Current Version**: 1.0.1+1  
**Status**: Active Development  
**Last Updated**: December 5, 2025

---

## 🗺️ Roadmap

### Upcoming Features
- [ ] Push notifications for requests and messages
- [ ] Item location mapping with Google Maps
- [ ] Advanced search filters (distance, category)
- [ ] User verification system
- [ ] Report inappropriate content
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Social media sharing
- [ ] Item wishlists
- [ ] Donation history analytics

---

**Built with ❤️ using Flutter**

