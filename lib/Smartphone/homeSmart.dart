import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stocktrue/Achats/Achats.dart';
import 'package:stocktrue/Paternars.dart';
import 'package:stocktrue/Produits/product.dart';
import 'package:stocktrue/Util.dart';
import 'package:stocktrue/Ventes/vente.dart';

class HomeSmart extends StatefulWidget {
  const HomeSmart({super.key});

  @override
  State<HomeSmart> createState() => _HomeSmartState();
}

class _HomeSmartState extends State<HomeSmart> {
  int myindex = 0;
  List widgetlist = [
    const Product(),
    const Achats(),
    const Ventes(),
 
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
 
      body: widgetlist[myindex],
      bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          unselectedItemColor: Colors.black45,
          showUnselectedLabels: true,
          selectedItemColor: princip(),
          elevation: 0,
          onTap: (index) {
            setState(() {
              myindex = index;
            });
          },
          currentIndex: myindex,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: "Produits"),
            BottomNavigationBarItem(
                icon: Icon(Icons.business_center_outlined), label: "Achats"),
            BottomNavigationBarItem(icon: Icon(Icons.sell), label: "Ventes"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_2_outlined), label: "Partenaires")
          ]),
    );
  }

 
}
