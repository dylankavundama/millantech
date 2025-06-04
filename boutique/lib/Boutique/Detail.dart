// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/Boutique/fullScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ip.dart';

class DetailproduitUser extends StatefulWidget {
  final String code;
  final String desigantion;
  final String Prix;
  final String imageUrl;

  const DetailproduitUser(this.code, this.desigantion, this.Prix, this.imageUrl,
      {super.key});

  @override
  State<DetailproduitUser> createState() => _DetailproduitUserState();
}

class _DetailproduitUserState extends State<DetailproduitUser> {
  List dataens = [];
  List recentProducts = [];

  @override
  void initState() {
    super.initState();
    getrecords();
    _loadBannerAd();
    getRecentProducts();
  }

  Future<void> getrecords() async {
    final response = await http.post(
      Uri.parse("$Adress_IP/PRODUIT/gettrie.php"),
      body: {"id": widget.code},
    );

    if (response.statusCode == 200) {
      setState(() {
        dataens = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de chargement du produit")),
      );
    }
  }

  Future<void> getRecentProducts() async {
    final response =
        await http.get(Uri.parse("$Adress_IP/PRODUIT/getproduit.php"));

    if (response.statusCode == 200) {
      final List<dynamic> products = jsonDecode(response.body);
      setState(() {
        recentProducts = products.where((p) => p["id"] != widget.code).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Erreur de chargement des produits récents")),
      );
    }
  }

  void commanderViaWhatsApp() async {
    final message = Uri.encodeComponent("Bonjour Phonexa \n\n"
        "Je souhaite commander le produit : ${widget.desigantion}\n"
        "Code Produit : ${widget.code}\n"
        "Prix : ${widget.Prix} \$ \n");

    final url = "https://wa.me/+243819782016?text=$message";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Impossible d'ouvrir WhatsApp. Assurez-vous que l'application est installée."),
        ),
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

//pub

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8882238368661853/1006164136',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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
              child: Image.asset(
                height: 130,
                'assets/ld.gif',
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                  const SizedBox(height: 30),
                  if (recentProducts.isNotEmpty) ...[
                    const Text(
                      "Derniers produits",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                                        if (_isAdLoaded)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                      ),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentProducts.length,
                        itemBuilder: (context, index) {
                          final product = recentProducts[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailproduitUser(
                                    product["code"],
                                    product["designation"],
                                    product["prixu"],
                                    product["image"],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product["image"],
                                      height: 100,
                                      width: 140,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product["designation"] ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text("${product["prixu"]} \$"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  ],
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
