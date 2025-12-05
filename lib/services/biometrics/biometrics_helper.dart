import 'biometrics_helper_stub.dart'
    if (dart.library.io) 'biometrics_helper_mobile.dart'
    if (dart.library.html) 'biometrics_helper_web.dart';

dynamic getBiometricsHelper() => getHelper();
