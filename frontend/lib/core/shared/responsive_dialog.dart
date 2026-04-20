import 'package:flutter/material.dart';

class ResponsiveDialog extends StatelessWidget {
  const ResponsiveDialog({
    required this.title,
    required this.child,
    required this.actions,
    this.maxWidth = 420,
    super.key,
  });

  final Widget title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return AlertDialog(
      title: title,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: screenHeight * 0.62,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: child,
        ),
      ),
      actions: actions,
    );
  }
}
