import 'dart:html' as html;

import 'pwa_install_controller.dart';

PwaInstallController createPwaInstallController() {
  return _WebPwaInstallController();
}

class _WebPwaInstallController extends PwaInstallController {
  _WebPwaInstallController() {
    _isInstalled = _computeStandalone();
    _needsIosInstructions = _computeIosSafari();

    html.window.addEventListener('beforeinstallprompt', _handleBeforeInstallPrompt);
    html.window.addEventListener('appinstalled', _handleAppInstalled);
  }

  Object? _deferredPrompt;
  late bool _isInstalled;
  late bool _needsIosInstructions;

  @override
  bool get isAvailable => !_isInstalled && (_deferredPrompt != null || _needsIosInstructions);

  @override
  bool get isInstalled => _isInstalled;

  @override
  bool get needsIosInstructions => _needsIosInstructions;

  @override
  Future<PwaInstallOutcome> install() async {
    if (_isInstalled) {
      return PwaInstallOutcome.alreadyInstalled;
    }

    if (_deferredPrompt != null) {
      final promptEvent = _deferredPrompt as dynamic;
      promptEvent.prompt();

      final choice = await (promptEvent.userChoice as Future<Object?>);

      final outcome = (choice as dynamic).outcome as String?;
      _deferredPrompt = null;
      notifyListeners();

      return outcome == 'accepted'
          ? PwaInstallOutcome.installed
          : PwaInstallOutcome.dismissed;
    }

    if (_needsIosInstructions) {
      return PwaInstallOutcome.instructions;
    }

    return PwaInstallOutcome.unavailable;
  }

  @override
  void dispose() {
    html.window.removeEventListener(
      'beforeinstallprompt',
      _handleBeforeInstallPrompt,
    );
    html.window.removeEventListener('appinstalled', _handleAppInstalled);
    super.dispose();
  }

  void _handleBeforeInstallPrompt(html.Event event) {
    (event as dynamic).preventDefault();
    _deferredPrompt = event;
    notifyListeners();
  }

  void _handleAppInstalled(html.Event event) {
    _deferredPrompt = null;
    _isInstalled = true;
    notifyListeners();
  }

  bool _computeStandalone() {
    final displayModeStandalone = html.window.matchMedia('(display-mode: standalone)').matches;
    final navigatorStandalone = (html.window.navigator as dynamic).standalone == true;

    return displayModeStandalone || navigatorStandalone;
  }

  bool _computeIosSafari() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final isIos = userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
    final isSafari = userAgent.contains('safari') &&
        !userAgent.contains('crios') &&
        !userAgent.contains('fxios') &&
        !userAgent.contains('edgios');

    return isIos && isSafari && !_computeStandalone();
  }
}
