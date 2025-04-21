import 'package:flutter/material.dart';
import 'package:money_tracker/providers/currency_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'utils/version_util.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/onboarding_dialog.dart';
import 'services/app_open_ad_manager.dart';
import 'services/app_lifecycle_reactor.dart';

late AppOpenAdManager appOpenAdManager;
late AppLifecycleReactor appLifecycleReactor;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print('Background message received: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Version Utility
  await VersionUtil.initialize();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Get the FCM token
  messaging.getToken().then((token) {
    print("FCM Token: $token");
  }).catchError((error) {
    // Handle the error gracefully
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

  // Initialize MobileAds
  await MobileAds.instance.initialize();

  // Initialize AppOpenAd manager
  appOpenAdManager = AppOpenAdManager();
  appOpenAdManager.loadAd();

  // Setup lifecycle reactor
  appLifecycleReactor = AppLifecycleReactor(
    appOpenAdManager: appOpenAdManager,
  );
  appLifecycleReactor.listenToAppStateChanges();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => CurrencyProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Money Tracker',
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
            iconTheme: const IconThemeData(color: Colors.white70),
            listTileTheme: const ListTileThemeData(iconColor: Colors.white70),
          ),
          home: const MainScreen(),
        );
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

  final List<Widget> _screens = [
    const HomeScreen(),
    const TransactionsScreen(),
    const CategoriesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

      if (isFirstLaunch) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const OnboardingDialog(),
        );
        await prefs.setBool('is_first_launch', false);
      }

      if (!mounted) return;
      context.read<TransactionProvider>().loadProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
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
                _buildNavItem(2, Icons.category_outlined, Icons.category),
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
