import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/player_provider.dart';
import 'providers/score_provider.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/leaderboard_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize services
  final authService = AuthService();
  final firebaseService = FirebaseService();
  final storageService = StorageService(
    authService: authService,
    firebaseService: firebaseService,
  );
  await storageService.initialize();

  runApp(MyApp(
    authService: authService,
    firebaseService: firebaseService,
    storageService: storageService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final FirebaseService firebaseService;
  final StorageService storageService;

  const MyApp({
    Key? key,
    required this.authService,
    required this.firebaseService,
    required this.storageService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<FirebaseService>.value(value: firebaseService),
        Provider<StorageService>.value(value: storageService),
        Provider<LeaderboardService>(
          create: (_) => LeaderboardService(
            storageService,
            authService: authService,
            firebaseService: firebaseService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storageService: storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ScoreProvider(storageService),
        ),
      ],
      child: MaterialApp(
        title: 'Hub Smart Games',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}
