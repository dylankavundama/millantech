import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stocktrue/Achats/Achats.dart';
import 'package:stocktrue/Login/authentification.dart';
import 'package:stocktrue/Paternars.dart';
import 'package:stocktrue/Produits/product.dart';
import 'package:stocktrue/Util.dart';
import 'package:stocktrue/Ventes/vente.dart';

import '../Clients/home.dart';

class HomeBarAgent extends StatefulWidget {
  const HomeBarAgent({super.key});

  @override
  State<HomeBarAgent> createState() => _HomeBarAgentState();
}

class _HomeBarAgentState extends State<HomeBarAgent> {
  int myindex = 0;
  List widgetlist = [
    const Product(),
    // const Achats(),
    const Ventes(),
    const HomeClient()
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Espace Agent"),
      ),
      // drawer: _buildDrawer(),
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
            // BottomNavigationBarItem(
            //     icon: Icon(Icons.business_center_outlined), label: "Achats"),
            BottomNavigationBarItem(icon: Icon(Icons.sell), label: "Ventes"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_2_outlined), label: "Clients")
          ]),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.orangeAccent,
            ),
            child: Text(
              'Gestion-Admin',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag, color: Colors.orangeAccent),
            title: Text(
              '---Millan Tech - Agent',
              style: GoogleFonts.lato(fontSize: 16),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
              );
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.phone_android, color: Colors.orangeAccent),
            title: Text(
              'Smart Phone',
              style: GoogleFonts.lato(fontSize: 16),
            ),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.orangeAccent),
            title: Text(
              'Paramètres',
              style: GoogleFonts.lato(fontSize: 16),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
