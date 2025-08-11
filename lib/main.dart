// lib/main.dart

import 'package:flutter/material.dart';
// CORRECTED: Use 'rideshare_app' instead of 'rideshare'
import 'package:rideshare_app/routing/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Rideshare App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      // This will now work correctly
      routerConfig: AppRouter.router,
    );
  }
}