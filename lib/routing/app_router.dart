// lib/routing/app_router.dart -- CORRECTED VERSION

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideshare_app/models/ride_model.dart';
import 'package:rideshare_app/screens/chat_screen.dart';
import 'package:rideshare_app/screens/initial_screen.dart';
import 'package:rideshare_app/screens/post_ride_screen.dart';
import 'package:rideshare_app/screens/ride_share_screen.dart';

class AppRouter {
  // This can remain as a static constant.
  static const String currentUserName = 'Nagaraj'; // TODO: Change to your name

  // THE FIX:
  // Instead of a 'static final' variable which is created immediately,
  // we use a 'static' method. This allows us to control exactly when the
  // GoRouter instance is created. We will call this method from main.dart
  // AFTER Amplify is configured.
  static GoRouter createRouter() {
    return GoRouter(
      // The initial location when the app starts.
      initialLocation: '/',

      // Define all the application routes.
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
            // Safely handle extra data for editing a ride.
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
            // It's safer to check if the `extra` data is of the correct type
            // to prevent crashes if navigation happens incorrectly.
            if (state.extra is Ride) {
              final ride = state.extra as Ride;
              return ChatScreen(ride: ride);
            } else {
              // If the required ride data is missing, navigate to a safe fallback screen.
              // This prevents the app from crashing.
              return const InitialScreen();
            }
          },
        ),
      ],
    );
  }
}