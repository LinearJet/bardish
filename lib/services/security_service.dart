import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'biometrics/biometrics_helper.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final _biometrics = getBiometricsHelper();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _pinKey = 'user_pin';
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  Future<bool> get isBiometricsAvailable async {
    return await _biometrics.isAvailable;
  }

  Future<bool> authenticate({String reason = 'Please authenticate to access Private Space'}) async {
    // Check if biometrics are enabled in settings
    final String? bioEnabled = await _storage.read(key: _biometricsEnabledKey);
    if (bioEnabled != 'true') {
      return false; // Biometrics disabled or not set, fall back to PIN in UI
    }
    return await _biometrics.authenticate(reason: reason);
  }

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == pin;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
  }

  Future<bool> isBiometricsEnabled() async {
    final val = await _storage.read(key: _biometricsEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsEnabledKey, value: enabled.toString());
  }
}