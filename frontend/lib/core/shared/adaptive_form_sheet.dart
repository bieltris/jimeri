import 'dart:math' as math;

import 'package:flutter/material.dart';

Future<T?> showAdaptiveFormSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final isMobile = MediaQuery.of(context).size.width < 640;

  if (isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: builder,
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: builder,
  );
}

class AdaptiveFormContainer extends StatelessWidget {
  const AdaptiveFormContainer({
    required this.title,
    required this.child,
    required this.actions,
    this.maxWidth = 460,
    super.key,
  });

  final Widget title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 640;

    if (isMobile) {
      return _SheetFrame(
        maxWidth: maxWidth,
        title: title,
        actions: actions,
        child: child,
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _CardFrame(
            title: title,
            actions: actions,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.maxWidth,
    required this.title,
    required this.actions,
    required this.child,
  });

  final double maxWidth;
  final Widget title;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomInset = mediaQuery.viewInsets.bottom;
    final targetHeight = math.max(380.0, screenHeight * 0.82);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minWidth: math.min(mediaQuery.size.width, 280),
            ),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: targetHeight,
                child: _FormChrome(
                  title: title,
                  actions: actions,
                  child: child,
                  showHandle: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.title,
    required this.actions,
    required this.child,
  });

  final Widget title;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 280,
          maxHeight: math.min(screenHeight - 48, 620),
        ),
        child: _FormChrome(
          title: title,
          actions: actions,
          child: child,
          showHandle: false,
        ),
      ),
    );
  }
}

class _FormChrome extends StatelessWidget {
  const _FormChrome({
    required this.title,
    required this.actions,
    required this.child,
    required this.showHandle,
  });

  final Widget title;
  final List<Widget> actions;
  final Widget child;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHandle)
            Align(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Fechar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              child: child,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 12,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}
