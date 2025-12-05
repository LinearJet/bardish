
class BiometricsHelperWeb {
  // WebAuthn implementation can go here later
  Future<bool> get isAvailable async => false; // Or true if we implement Passkeys

  Future<bool> authenticate({String reason = 'Authenticate'}) async {
    // For now, return false to force PIN usage on Web
    // OR implement basic WebAuthn prompt
    return false;
  }
}

BiometricsHelperWeb getHelper() => BiometricsHelperWeb();
