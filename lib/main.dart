import 'package:flutter/material.dart';
import 'package:money_tracker/providers/currency_provider.dart';
import 'package:money_tracker/providers/budget_alert_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'utils/version_util.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/currency_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'services/app_open_ad_manager.dart';
import 'services/app_lifecycle_reactor.dart';
import 'services/deep_link_service.dart';
import 'services/app_rating_service.dart';
import 'db/database_helper.dart';

late AppOpenAdManager appOpenAdManager;
late AppLifecycleReactor appLifecycleReactor;
late DeepLinkService deepLinkService;
late AppRatingService appRatingService;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print('Background message received: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force database reload to ensure schema is updated
  await DatabaseHelper.instance.forceReload();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Version Utility - lightweight operation
  await VersionUtil.initialize();

  // Start the app immediately while other services initialize in background
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => BudgetAlertProvider()),
      ],
      child: const MyApp(),
    ),
  );

  // Now perform remaining initialization tasks after app has started
  _initializeRemainingServices();
}

// All non-critical initialization moved to this function that runs after app launch
Future<void> _initializeRemainingServices() async {
  // Set up Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions WITHOUT awaiting
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  messaging.requestPermission().then((settings) {
    print('Notification permission status: ${settings.authorizationStatus}');
  }).catchError((error) {
    print('Error requesting notification permissions: $error');
  });

  // Create the notification channel for budget alerts (can be done in background)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'budget_alerts_channel',
    'Budget Alerts',
    description: 'Notifications for budget alerts',
    importance: Importance.high,
  );

  // Create the notification channel on the device
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Get the FCM token without blocking
  messaging.getToken().then((token) {
    print("FCM Token: $token");
  }).catchError((error) {
    print("Failed to get FCM token: $error");
  });

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel', // Channel ID
            'Default', // Channel name
            channelDescription: 'Default channel for notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  // Initialize MobileAds - can be delayed
  MobileAds.instance.initialize();

  // Initialize AppOpenAd manager
  appOpenAdManager = AppOpenAdManager();
  appOpenAdManager.loadAd();

  // Setup lifecycle reactor
  appLifecycleReactor = AppLifecycleReactor(
    appOpenAdManager: appOpenAdManager,
  );
  appLifecycleReactor.listenToAppStateChanges();

  // Initialize DeepLinkService
  deepLinkService = DeepLinkService();
  await deepLinkService.initialize();

  // Initialize AppRatingService
  appRatingService = AppRatingService();
  await appRatingService.initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Builder(builder: (context) {
          // Initialize TransactionProvider with context
          Future.microtask(() {
            context.read<TransactionProvider>().setContext(context);
          });

          return MaterialApp(
            title: 'Budget Tracker',
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF2E5C88),
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF5F7FA),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFF5F7FA),
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF2E5C88),
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0A1929),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF0A1929),
                elevation: 0,
              ),
            ),
            home: const MainScreen(),
          );
        });
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TransactionsScreen(),
    const CurrencyConversionScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Perform initialization outside the build phase, but don't block UI
    _initializeAsync();
  }

  // Separate method for async initialization that won't block UI rendering
  Future<void> _initializeAsync() async {
    // Run in microtask to ensure UI is rendered first
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

      if (isFirstLaunch && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
        await prefs.setBool('is_first_launch', false);
      }

      if (mounted) {
        // Load profiles and alerts in parallel instead of sequentially
        await Future.wait([
          context.read<TransactionProvider>().loadProfiles(),
          context.read<BudgetAlertProvider>().loadAlerts(),
        ]);

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isInitialized
          ? _screens[_selectedIndex]
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    "Getting everything ready...",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  )
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0A1929)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home),
                _buildNavItem(1, Icons.receipt_outlined, Icons.receipt),
                _buildNavItem(2, Icons.currency_exchange_outlined,
                    Icons.currency_exchange),
                _buildNavItem(3, Icons.settings_outlined, Icons.settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2E5C88)
            : const Color(0xFF1E3D59)
        : Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : const Color(0xFF6B7F99);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          const Color(0xFF2E5C88).withOpacity(0.2),
                          const Color(0xFF15294D).withOpacity(0.15),
                        ]
                      : [
                          const Color(0xFF2E5C88).withOpacity(0.15),
                          const Color(0xFF1E3D59).withOpacity(0.1),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Icon(isSelected ? selectedIcon : icon, color: color),
      ),
    );
  }
}
