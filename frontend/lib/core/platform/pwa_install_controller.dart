import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pwa_install_controller_stub.dart'
    if (dart.library.html) 'pwa_install_controller_web.dart';

enum PwaInstallOutcome {
  installed,
  dismissed,
  instructions,
  unavailable,
  alreadyInstalled,
}

abstract class PwaInstallController extends ChangeNotifier {
  bool get isAvailable;
  bool get isInstalled;
  bool get needsIosInstructions;

  Future<PwaInstallOutcome> install();
}

final pwaInstallProvider = ChangeNotifierProvider<PwaInstallController>((ref) {
  return createPwaInstallController();
});
