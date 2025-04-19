import 'package:flutter/material.dart';
import 'dart:async'; // Add this import
import 'app_open_ad_manager.dart';

class AppLifecycleReactor {
  final AppOpenAdManager appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  void listenToAppStateChanges() {
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream
        .listen((state) => _onAppStateChanged(state));
  }

  void _onAppStateChanged(AppState appState) {
    // Show an open app ad when the app is foregrounded
    if (appState == AppState.foreground) {
      appOpenAdManager.showAdIfAvailable();
    }
  }
}

/// App state event notifier
class AppStateEventNotifier {
  static final StreamController<AppState> _appStateController =
      StreamController<AppState>.broadcast();

  static bool _isListening = false;

  static Stream<AppState> get appStateStream => _appStateController.stream;

  static void startListening() {
    if (_isListening) return;

    WidgetsBinding.instance
        .addObserver(_AppLifecycleObserver(_appStateController));
    _isListening = true;
  }

  static void dispose() {
    _appStateController.close();
  }
}

/// App state definitions
enum AppState {
  background,
  foreground,
}

/// Listens to lifecycle changes and broadcasts app state changes
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final StreamController<AppState> controller;

  _AppLifecycleObserver(this.controller);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      controller.add(AppState.foreground);
    } else if (state == AppLifecycleState.paused) {
      controller.add(AppState.background);
    }
  }
}
