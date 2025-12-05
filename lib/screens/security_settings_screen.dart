import 'package:flutter/material.dart';
import '../services/security_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final SecurityService _securityService = SecurityService();
  bool _hasPin = false;
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hasPin = await _securityService.hasPin();
    final bioEnabled = await _securityService.isBiometricsEnabled();
    final bioAvailable = await _securityService.isBiometricsAvailable;

    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _biometricsEnabled = bioEnabled;
        _biometricsAvailable = bioAvailable;
        _isLoading = false;
      });
    }
  }

  Future<void> _setPin() async {
    // Simple PIN setting dialog for now
    String newPin = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set PIN'),
          content: TextField(
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            onChanged: (value) => newPin = value,
            decoration: const InputDecoration(hintText: 'Enter 4-digit PIN'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newPin.length == 4) {
                  Navigator.pop(context);
                  _savePin(newPin);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePin(String pin) async {
    await _securityService.setPin(pin);
    _loadSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN set successfully')),
      );
    }
  }

  Future<void> _confirmRemovePin() async {
    String enteredPin = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disable PIN?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your current PIN to disable security.'),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                onChanged: (value) => enteredPin = value,
                decoration: const InputDecoration(hintText: 'Current PIN'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (enteredPin.length == 4) {
                  final isValid = await _securityService.verifyPin(enteredPin);
                  if (isValid) {
                    Navigator.pop(context); // Close dialog
                    _removePin();
                  } else {
                    // Show error
                     if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Incorrect PIN')),
                      );
                    }
                  }
                }
              },
              child: const Text('Disable'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removePin() async {
    await _securityService.removePin();
    await _securityService.setBiometricsEnabled(false);
    _loadSettings();
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value && !_hasPin) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a PIN first')),
      );
      return;
    }
    await _securityService.setBiometricsEnabled(value);
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Security',
                      style: TextStyle(
                        fontSize: 36,
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.colorScheme.primary, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                     _buildSwitchItem(
                      title: 'Use PIN',
                      subtitle: _hasPin ? 'PIN is set' : 'Set a 4-digit PIN to secure your notes',
                      value: _hasPin,
                      onChanged: (val) {
                        if (val) {
                          _setPin();
                        } else {
                          _confirmRemovePin();
                        }
                      },
                      context: context,
                    ),
                    if (_biometricsAvailable)
                      _buildSwitchItem(
                        title: 'Biometric Unlock',
                        subtitle: 'Use Fingerprint or FaceID',
                        value: _biometricsEnabled,
                        onChanged: _toggleBiometrics,
                        context: context,
                        enabled: _hasPin,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required BuildContext context,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
