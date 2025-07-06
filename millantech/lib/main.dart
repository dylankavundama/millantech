import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocktrue/HomeScreenBar.dart'; // For HomeBarAdmin
import 'package:stocktrue/Login/authentification.dart'; // For AuthPage
import 'package:stocktrue/agent/homeBarAgent.dart'; // For HomeBarAgent

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Check if it's the first launch
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  // Check if a user is logged in
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Check the user's role if logged in
  // Default to false (Admin) if not found, as Admin is the default for password login
  bool isTechnician = prefs.getBool('isTechnician') ?? false;

  runApp(MyApp(
    showAuthPage: isFirstLaunch,
    isLoggedIn: isLoggedIn,
    isTechnician: isTechnician, // Pass the technician status
  ));
}

class MyApp extends StatelessWidget {
  final bool showAuthPage;
  final bool isLoggedIn;
  final bool isTechnician; // New parameter to store the user's role

  const MyApp({
    Key? key,
    required this.showAuthPage,
    required this.isLoggedIn,
    required this.isTechnician, // Initialize the new parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget initialRoute;

    if (showAuthPage) {
      // If it's the first launch, always show the FirstLaunchWrapper (which leads to AuthPage)
      initialRoute = const FirstLaunchWrapper();
    } else {
      // If not the first launch, check login status and role
      if (isLoggedIn) {
        if (isTechnician) {
          initialRoute = const HomeBarAgent(); // Navigate to Agent home
        } else {
          initialRoute = const HomeBarAdmin(); // Navigate to Admin home
        }
      } else {
        initialRoute = const AuthPage(); // Not logged in, show AuthPage
      }
    }

    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      title: 'Gebutik',
      debugShowCheckedModeBanner: false,
      home: initialRoute, // Use the determined initial route
    );
  }
}

class FirstLaunchWrapper extends StatelessWidget {
  const FirstLaunchWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _markFirstLaunch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const AuthPage(); // Affiche AuthPage après le premier lancement
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Future<void> _markFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
  }
}
