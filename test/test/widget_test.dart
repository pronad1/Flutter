import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:software/main.dart';

void main() {
  setUpAll(() async {
    // Initialize a fake Firebase for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'fake_apiKey',
        appId: 'fake_appId',
        messagingSenderId: 'fake_senderId',
        projectId: 'fake_projectId',
      ),
    );
  });

  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const ReuseHubApp());

    // Trigger a frame
    await tester.pump();

    // Verify the splash screen is shown by checking route or widget
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
