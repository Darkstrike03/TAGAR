import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class TagarApp extends StatelessWidget {
  const TagarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tagar',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
