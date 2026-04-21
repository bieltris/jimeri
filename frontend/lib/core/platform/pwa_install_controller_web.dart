import 'dart:html' as html;

import 'pwa_install_controller.dart';

PwaInstallController createPwaInstallController() {
  return _WebPwaInstallController();
}

class _WebPwaInstallController extends PwaInstallController {
  _WebPwaInstallController() {
    try {
      _isInstalled = _computeStandalone();
      _needsIosInstructions = _computeIosSafari();

      html.window.addEventListener(
        'beforeinstallprompt',
        _handleBeforeInstallPrompt,
      );
      html.window.addEventListener('appinstalled', _handleAppInstalled);
    } catch (_) {
      _initFailed = true;
      _isInstalled = false;
      _needsIosInstructions = false;
    }
  }

  Object? _deferredPrompt;
  bool _initFailed = false;
  late bool _isInstalled;
  late bool _needsIosInstructions;

  @override
  bool get isAvailable =>
      !_initFailed && !_isInstalled && (_deferredPrompt != null || _needsIosInstructions);

  @override
  bool get isInstalled => _isInstalled;

  @override
  bool get needsIosInstructions => _needsIosInstructions;

  @override
  Future<PwaInstallOutcome> install() async {
    if (_initFailed) {
      return PwaInstallOutcome.unavailable;
    }

    if (_isInstalled) {
      return PwaInstallOutcome.alreadyInstalled;
    }

    if (_deferredPrompt != null) {
      try {
        final promptEvent = _deferredPrompt as dynamic;
        promptEvent.prompt();

        final choice = await (promptEvent.userChoice as Future<Object?>);

        final outcome = (choice as dynamic).outcome as String?;
        _deferredPrompt = null;
        notifyListeners();

        return outcome == 'accepted'
            ? PwaInstallOutcome.installed
            : PwaInstallOutcome.dismissed;
      } catch (_) {
        _deferredPrompt = null;
        notifyListeners();
        return PwaInstallOutcome.unavailable;
      }
    }

    if (_needsIosInstructions) {
      return PwaInstallOutcome.instructions;
    }

    return PwaInstallOutcome.unavailable;
  }

  @override
  void dispose() {
    if (!_initFailed) {
      html.window.removeEventListener(
        'beforeinstallprompt',
        _handleBeforeInstallPrompt,
      );
      html.window.removeEventListener('appinstalled', _handleAppInstalled);
    }
    super.dispose();
  }

  void _handleBeforeInstallPrompt(html.Event event) {
    try {
      (event as dynamic).preventDefault();
      _deferredPrompt = event;
      notifyListeners();
    } catch (_) {
      _deferredPrompt = null;
    }
  }

  void _handleAppInstalled(html.Event event) {
    _deferredPrompt = null;
    _isInstalled = true;
    notifyListeners();
  }

  bool _computeStandalone() {
    final displayModeStandalone = html.window.matchMedia('(display-mode: standalone)').matches;
    final navigatorStandalone = _navigatorStandalone();

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

  bool _navigatorStandalone() {
    try {
      final standalone = (html.window.navigator as dynamic).standalone;
      return standalone == true;
    } catch (_) {
      return false;
    }
  }
}
