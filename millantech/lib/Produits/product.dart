import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
import 'package:stocktrue/Login/authentification.dart';
import 'package:stocktrue/Produits/HomeCat.dart';
import 'package:stocktrue/Util.dart';
import 'Allproduct.dart';

class Product extends StatefulWidget {
  const Product({super.key});

  @override
  State<Product> createState() => _ProductState();
}

class _ProductState extends State<Product> {
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    // Redirige vers AuthPage
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          // centerTitle: true,
          actions: [
            IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
          ],
          title: const AppTitle()),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            //Text("data"),
            Material(
              child: Container(
                  height: 55,
                  color: Colors.white,
                  child: TabBar(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(
                          top: 10, left: 10, right: 10, bottom: 10),
                      unselectedLabelColor: Colors.black,
                      labelColor: white(),
                      indicatorSize: TabBarIndicatorSize.label,
                      indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.orangeAccent),
                      tabs: [
                        Tab(
                          child: Container(
                            height: 37,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: Colors.orangeAccent, width: 1)),
                            child: const Align(
                              alignment: Alignment.center,
                              child: Text("Produits"),
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            height: 37,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: Colors.orangeAccent, width: 1)),
                            child: const Align(
                              alignment: Alignment.center,
                              child: Text("Categories"),
                            ),
                          ),
                        ),
                      ])),
            ),
            const Expanded(
                child: TabBarView(
              children: [Allproduct(), Cat()],
            ))
          ],
        ),
      ),
    );
  }
}
