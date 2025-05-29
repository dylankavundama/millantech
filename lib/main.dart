import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocktrue/HomeScreenBar.dart';
import 'package:stocktrue/Login/authentification.dart';

 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(
    showAuthPage: isFirstLaunch,
    isLoggedIn: isLoggedIn,
  ));
}

class MyApp extends StatelessWidget {
  final bool showAuthPage;
  final bool isLoggedIn;

  const MyApp({Key? key, required this.showAuthPage, required this.isLoggedIn})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      title: 'StockTrue',
      debugShowCheckedModeBanner: false,
      home: showAuthPage
          ? const FirstLaunchWrapper()
          : (isLoggedIn ? const HomeMillan() : const AuthPage()),
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
