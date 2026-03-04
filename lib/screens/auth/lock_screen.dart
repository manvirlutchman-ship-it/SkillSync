import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/biometrics_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAuthenticate());
  }

  Future<void> _tryAuthenticate() async {
    if (_authenticating) return; // prevent concurrent calls
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final biometrics = Provider.of<BiometricsProvider>(context, listen: false);

    final ok = await biometrics.authenticate();

    if (!mounted) return;

    if (ok) {
      final bm = Provider.of<BiometricsProvider>(context, listen: false);
      bm.markUnlocked();
      Navigator.of(context).pop();
    }
    else {
      setState(() {
        _authenticating = false;
        _error = biometrics.permanentlyLocked
            ? 'Too many failed attempts. Close and reopen the app.'
            : (biometrics.lastError ?? 'Authentication failed. Try again.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fingerprint, size: 72, color: colorScheme.primary),
                const SizedBox(height: 20),
                Text(
                  'Biometrics required',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use your fingerprint to unlock the app',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_authenticating)
                  CircularProgressIndicator(color: colorScheme.primary),
                if (!_authenticating)
                  Consumer<BiometricsProvider>(
                      builder: (context, bm, _) {
                    final disabled = bm.permanentlyLocked;
                    return ElevatedButton(
                      onPressed: disabled ? null : _tryAuthenticate,
                      child: Text(disabled ? 'Locked' : 'Authenticate'),
                    );
                  }),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}