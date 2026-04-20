import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    required this.title,
    required this.description,
    required this.child,
    this.action,
    super.key,
  });

  final String title;
  final String description;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      if (action != null) action!,
                    ],
                  ),
                  const SizedBox(height: 32),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
