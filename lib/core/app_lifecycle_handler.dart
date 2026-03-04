import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/biometrics_provider.dart';
import 'package:skillsync/screens/auth/lock_screen.dart';
import '../main.dart';

class AppLifecycleHandler extends StatefulWidget {
  final Widget child;
  const AppLifecycleHandler({super.key, required this.child});

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {

  bool _lockVisible = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🔐 Listen for Firebase session restoration (cold start fix)
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        final bm = Provider.of<BiometricsProvider>(context, listen: false);

        // Wait for provider to finish loading SharedPreferences
        await bm.ready;

        _checkAndLock();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final bm = Provider.of<BiometricsProvider>(context, listen: false);

    if (!bm.isEnabled) return;

    if (state == AppLifecycleState.paused) {
      bm.markAppLocked();
    }

    if (state == AppLifecycleState.resumed) {
      await bm.ready; // ensure provider is loaded
      _checkAndLock();
    }
  }

  Future<void> _checkAndLock() async {
    final user = FirebaseAuth.instance.currentUser;
    final bm = Provider.of<BiometricsProvider>(context, listen: false);

    debugPrint("CHECK LOCK -> user: $user, enabled: ${bm.isEnabled}, shouldLock: ${bm.shouldLock}");

    if (user == null) return;
    if (!bm.isEnabled) return;
    if (!bm.shouldLock) return;
    if (_lockVisible) return;

    _lockVisible = true;

    await navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const LockScreen(),
        fullscreenDialog: true,
      ),
    );

    _lockVisible = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}