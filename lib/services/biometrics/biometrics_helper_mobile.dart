import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricsHelperMobile {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get isAvailable async {
    // Linux is not officially supported by local_auth yet, avoid runtime crash
    if (Platform.isLinux) return false;
    
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Authenticate'}) async {
    if (Platform.isLinux) return false;

    try {
      // We use default options to avoid build errors on Linux where AuthenticationOptions
      // might not be resolving correctly or if there's a version mismatch.
      // Default is usually biometricOnly: false, stickyAuth: false.
      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException {
      return false;
    }
  }
}

BiometricsHelperMobile getHelper() => BiometricsHelperMobile();