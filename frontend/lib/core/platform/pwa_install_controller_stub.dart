import 'pwa_install_controller.dart';

PwaInstallController createPwaInstallController() {
  return _UnavailablePwaInstallController();
}

class _UnavailablePwaInstallController extends PwaInstallController {
  @override
  bool get isAvailable => false;

  @override
  bool get isInstalled => false;

  @override
  bool get needsIosInstructions => false;

  @override
  Future<PwaInstallOutcome> install() async {
    return PwaInstallOutcome.unavailable;
  }
}
