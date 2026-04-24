import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_smart_games/main.dart';
import 'package:hub_smart_games/services/ads_service.dart';
import 'package:hub_smart_games/services/auth_service.dart';
import 'package:hub_smart_games/services/firebase_service.dart';
import 'package:hub_smart_games/services/storage_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final authService = AuthService();
    final firebaseService = FirebaseService();
    final adsService = AdsService();
    final storageService = StorageService(
      authService: authService,
      firebaseService: firebaseService,
    );
    await storageService.initialize();
    await tester.pumpWidget(MyApp(
      authService: authService,
      firebaseService: firebaseService,
      storageService: storageService,
      adsService: adsService,
    ));

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
