import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/player_provider.dart';
import 'providers/score_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ads_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/leaderboard_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({Key? key}) : super(key: key);

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> with WidgetsBindingObserver {
  late final Future<_AppDependencies> _bootstrapFuture = _initialize();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setImmersiveMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _setImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: const [],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setImmersiveMode();
    }
  }

  Future<_AppDependencies> _initialize() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await Firebase.initializeApp();
    await Hive.initFlutter();

    final adsService = AdsService();
    await adsService.initialize();

    final authService = AuthService();
    final firebaseService = FirebaseService();
    final storageService = StorageService(
      authService: authService,
      firebaseService: firebaseService,
    );
    await storageService.initialize();

    return _AppDependencies(
      authService: authService,
      firebaseService: firebaseService,
      storageService: storageService,
      adsService: adsService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppDependencies>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            home: _BootstrapErrorScreen(
              error: snapshot.error,
            ),
          );
        }

        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            home: const SplashScreen(),
          );
        }

        final deps = snapshot.data!;
        return MyApp(
          authService: deps.authService,
          firebaseService: deps.firebaseService,
          storageService: deps.storageService,
          adsService: deps.adsService,
        );
      },
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  final Object? error;

  const _BootstrapErrorScreen({
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentRed.withAlpha(120)),
                ),
                child: const Icon(
                  Icons.cloud_off,
                  color: AppTheme.accentRed,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Não foi possível iniciar o app',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Verifique a conexão, o Firebase ou os serviços do aparelho e tente novamente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.accentRed.withAlpha(220),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDependencies {
  final AuthService authService;
  final FirebaseService firebaseService;
  final StorageService storageService;
  final AdsService adsService;

  _AppDependencies({
    required this.authService,
    required this.firebaseService,
    required this.storageService,
    required this.adsService,
  });
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final FirebaseService firebaseService;
  final StorageService storageService;
  final AdsService adsService;

  const MyApp({
    Key? key,
    required this.authService,
    required this.firebaseService,
    required this.storageService,
    required this.adsService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<FirebaseService>.value(value: firebaseService),
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<AdsService>.value(value: adsService),
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
          create: (_) => PlayerProvider(
            storageService,
            authService: authService,
          ),
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
