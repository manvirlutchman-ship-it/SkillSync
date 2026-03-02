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
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final biometrics = Provider.of<BiometricsProvider>(context, listen: false);
    final ok = await biometrics.authenticate();

    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      setState(() {
        _authenticating = false;
        _error = 'Authentication failed. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
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
                style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Use your fingerprint to unlock the app',
                style: TextStyle(color: colorScheme.secondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_authenticating) CircularProgressIndicator(color: colorScheme.primary),
              if (!_authenticating)
                ElevatedButton(
                  onPressed: _tryAuthenticate,
                  child: const Text('Authenticate'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
