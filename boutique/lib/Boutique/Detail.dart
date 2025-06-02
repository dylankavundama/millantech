// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/Boutique/fullScreen.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure url_launcher is in pubspec.yaml
import '../ip.dart'; // Ensure this path is correct and contains currentip()

class DetailproduitUser extends StatefulWidget {
  final String code;
  final String desigantion;
  final String Prix;
  final String imageUrl; // Image filename passed from Boutique

  const DetailproduitUser(this.code, this.desigantion, this.Prix, this.imageUrl,
      {super.key});

  @override
  State<DetailproduitUser> createState() => _DetailproduitUserState();
}

class _DetailproduitUserState extends State<DetailproduitUser> {
  List dataens = [];

  @override
  void initState() {
    super.initState();
    getrecords();
  }

  Future<void> getrecords() async {
    final response = await http.post(
      Uri.parse("$Adress_IP/produit/gettrie.php"),
      body: {"id": widget.code},
    );

    if (response.statusCode == 200) {
      setState(() {
        dataens = jsonDecode(response.body);
      });
    } else {
      // You might want a more specific error message here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de chargement du produit")),
      );
    }
  }

  void commanderViaWhatsApp() async {
    // Construct the full image URL from the image filename
    final fullImageUrl = "${widget.imageUrl}";

    // Construct the message with all product details, including the image URL
    final message = Uri.encodeComponent("Bonjour Phonexa \n\n"
        "Je souhaite commander le produit : ${widget.desigantion}\n"
        "Code Produit : ${widget.code}\n"
        "Prix : ${widget.Prix} \$ \n\n"
        //  "Photo du produit : $fullImageUrl" // Include the image URL here
        );

    final url = "https://wa.me/+243819782016?text=$message";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Impossible d'ouvrir WhatsApp. Assurez-vous que l'application est installée.")),
      );
    }
  }

  void appeler() async {
    const phoneNumber = 'tel:+243819782016';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de passer l'appel.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.call, color: Colors.white),
        onPressed: appeler,
      ),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(widget.desigantion),
      ),
      body: dataens.isEmpty
          ? Center(
              child: Image.network(
                  height: 150,
                  'https://i.pinimg.com/originals/66/22/ab/6622ab37c6db6ac166dfec760a2f2939.gif'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullscreenImagePage(
                                imageUrl: dataens[0]["image"]),
                          ),
                        );
                      },
                      child: Image.network(
                        "${dataens[0]["image"]}",
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 280,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              size: 80, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    dataens[0]["designation"] ?? "Sans nom",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dataens[0]["detail"]?.toString() ??
                        "Aucune description disponible",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          buildRowInfo("Quantité disponible :",
                              dataens[0]["quantite"]?.toString() ?? 'N/A'),
                          const Divider(),
                          buildRowInfo("Prix d'achat :",
                              "${dataens[0]["prixu"]?.toString() ?? '0'} \$"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: commanderViaWhatsApp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green[600],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon:
                          const Icon(Icons.shopping_cart, color: Colors.white),
                      label: const Text("Commander via WhatsApp",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget buildRowInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(fontSize: 16, color: Colors.black87)),
      ],
    );
  }
}
