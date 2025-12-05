
class BiometricsHelper {
  Future<bool> get isAvailable async => false;
  Future<bool> authenticate({String reason = 'Authenticate'}) async => false;
}

BiometricsHelper getHelper() => BiometricsHelper();
