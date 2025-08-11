// lib/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// CORRECTED IMPORTS:
import 'package:rideshare_app/models/ride_model.dart';
import 'package:rideshare_app/screens/chat_screen.dart';
import 'package:rideshare_app/screens/initial_screen.dart';
import 'package:rideshare_app/screens/post_ride_screen.dart';
import 'package:rideshare_app/screens/ride_share_screen.dart';

class AppRouter {
  static const String currentUserName = 'Nagaraj'; // TODO: Change to your name

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const InitialScreen(),
      ),
      GoRoute(
        path: '/ride-share',
        builder: (context, state) {
          return const RideShareScreen(currentUserName: currentUserName);
        },
      ),
      GoRoute(
        path: '/post_ride',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final rideToEdit = extra?['rideToEdit'] as Ride?;

          return PostRideScreen(
            rideToEdit: rideToEdit,
            currentUserName: extra?['currentUserName'] as String? ?? currentUserName,
          );
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final ride = state.extra as Ride;
          return ChatScreen(ride: ride);
        },
      ),
    ],
  );
}