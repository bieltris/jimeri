import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';

void main() {
  GoRouter.optionURLReflectsImperativeAPIs = true;

  runApp(
    const ProviderScope(
      child: JimeriApp(),
    ),
  );
}
