import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppSnackBar {
  static OverlayEntry? _currentEntry;
  static int _overlayVersion = 0;

  static void showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 2),
    BuildContext? context,
  }) {
    _show(message, Colors.green, duration: duration, context: context);
  }

  static void showError(
    String message, {
    Duration duration = const Duration(seconds: 3),
    BuildContext? context,
  }) {
    _show(message, Colors.red, duration: duration, context: context);
  }

  static void showWarning(
    String message, {
    Duration duration = const Duration(seconds: 3),
    BuildContext? context,
  }) {
    _show(message, Colors.orange, duration: duration, context: context);
  }

  static void _show(
    String message,
    Color backgroundColor, {
    Duration duration = const Duration(seconds: 3),
    BuildContext? context,
  }) {
    final overlay = _resolveOverlayState(context);
    if (overlay == null) {
      return;
    }

    _overlayVersion++;
    final currentVersion = _overlayVersion;

    _currentEntry?.remove();
    _currentEntry = null;

    final animationController = AnimationController(
      vsync: overlay,
      duration: const Duration(milliseconds: 300),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    final fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    _currentEntry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: AnimatedBuilder(
          animation: animationController,
          builder: (_, child) => FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(position: slideAnimation, child: child),
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentEntry!);
    animationController.forward();

    Future.delayed(duration, () async {
      if (currentVersion != _overlayVersion) {
        animationController.dispose();
        return;
      }

      await animationController.reverse();
      _currentEntry?.remove();
      _currentEntry = null;
      animationController.dispose();
    });
  }

  static OverlayState? _resolveOverlayState(BuildContext? context) {
    final scopedOverlay =
        context != null ? Overlay.maybeOf(context, rootOverlay: true) : null;
    if (scopedOverlay != null) {
      return scopedOverlay;
    }

    final rootContext = rootScaffoldMessengerKey.currentContext;
    if (rootContext == null) {
      return null;
    }

    return Overlay.maybeOf(rootContext, rootOverlay: true);
  }
}
