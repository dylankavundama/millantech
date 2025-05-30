import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stocktrue/loading.dart';

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
    return const MaterialApp(
        title: 'Phonexa',
        debugShowCheckedModeBanner: false,
        home: SplashScreen());
  }
}
