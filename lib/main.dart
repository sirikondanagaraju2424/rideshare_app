// lib/main.dart -- FINAL AND EXACTLY CORRECT CODE

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideshare_app/amplifyconfiguration.dart';

// THIS IMPORT IS THE CRITICAL FIX for the build error.
import 'package:rideshare_app/routing/app_router.dart';

// This import is also needed for the ModelProvider.
import 'package:rideshare_app/models/ModelProvider.dart';

Future<void> main() async {
  // Ensure Flutter engine is ready.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Wait for Amplify to be configured before doing anything else.
  await _configureAmplify();
  
  // Now that Amplify is ready, create the router instance.
  final router = AppRouter.createRouter();
  
  // Run the app, passing the router to the main widget.
  runApp(MyApp(router: router));
}

Future<void> _configureAmplify() async {
  try {
    // Create an instance of the API plugin and pass the generated ModelProvider to it.
    final apiPlugin = AmplifyAPI(modelProvider: ModelProvider.instance);
    
    // Add the configured apiPlugin along with the auth plugin.
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      apiPlugin, // Use the new apiPlugin instance
    ]);
    
    await Amplify.configure(amplifyconfig);
    print("Amplify configured successfully");

  } on AmplifyAlreadyConfiguredException {
      print("Tried to reconfigure Amplify; this is usually OK.");
  } catch (e) {
    print("Could not configure Amplify: $e");
  }
}

class MyApp extends StatelessWidget {
  final GoRouter router;

  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Rideshare App',
      debugShowCheckedModeBanner: false,
    );
  }
}