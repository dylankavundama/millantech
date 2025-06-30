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

  const DetailproduitUser(
    this.code,
    this.desigantion,
    this.Prix,
    this.imageUrl, {
    super.key,
  });

  @override
  State<DetailproduitUser> createState() => _DetailproduitUserState();
}

class _DetailproduitUserState extends State<DetailproduitUser> {
  // Use a nullable type for dataens as it might be empty initially or after an error
  Map<String, dynamic>? productDetails;
  List<dynamic> recentProducts = [];

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
    _loadBannerAd();
    _loadRecentProducts();
  }

  /// Fetches the details of the specific product.
  Future<void> _loadProductDetails() async {
    try {
      final response = await http.post(
        Uri.parse("$Adress_IP/PRODUIT/gettrie.php"),
        body: {"id": widget.code},
      );

      if (!mounted) return; // Check if the widget is still mounted

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        if (decodedData.isNotEmpty) {
          setState(() {
            productDetails = decodedData[0];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Produit non trouvé.")),
          );
          setState(() {
            productDetails = null; // Indicate that no product details were found
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Erreur de chargement du produit: ${response.statusCode}")),
        );
        setState(() {
          productDetails = null; // Indicate an error occurred
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau lors du chargement du produit: $e")),
      );
      setState(() {
        productDetails = null; // Indicate an error occurred
      });
    }
  }

  /// Fetches a list of recent products, excluding the current one.
  Future<void> _loadRecentProducts() async {
    try {
      final response =
          await http.get(Uri.parse("$Adress_IP/PRODUIT/getproduit.php"));

      if (!mounted) return; // Check if the widget is still mounted

      if (response.statusCode == 200) {
        final List<dynamic> products = jsonDecode(response.body);
        setState(() {
          recentProducts =
              products.where((p) => p["id_produit"] != widget.code).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Erreur de chargement des produits récents: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur réseau lors du chargement des produits récents: $e")),
      );
    }
  }

  /// Initiates a WhatsApp order message.
  void _commanderViaWhatsApp() async {
    final message = Uri.encodeComponent(
        "Bonjour Phonexa \n\n"
        "Je souhaite commander le produit : ${widget.desigantion}\n"
        "Code Produit : ${widget.code}\n"
        "Prix : ${widget.Prix} \$ \n");

    final url = "https://wa.me/+243819782016?text=$message";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Impossible d'ouvrir WhatsApp. Assurez-vous que l'application est installée."),
        ),
      );
    }
  }

  /// Initiates a phone call.
  void _appeler() async {
    const phoneNumber = 'tel:+243819782016';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de passer l'appel.")),
      );
    }
  }

  /// Loads the Google Mobile Ads banner.
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8882238368661853/1006164136',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) return;
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
        onPressed: _appeler,
      ),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(widget.desigantion),
      ),
      body: productDetails == null
          ? Center(
              child: Image.asset(
                height: 130,
                'assets/ld.gif', // Make sure this asset exists
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
                                imageUrl: productDetails!["image"] ?? ''),
                          ),
                        );
                      },
                      child: Image.network(
                        productDetails!["image"] ?? '', // Use null-aware operator
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
                    productDetails!["designation"] ?? "Sans nom",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    productDetails!["detail"]?.toString() ??
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
                          _buildRowInfo(
                              "Quantité disponible :",
                              productDetails!["quantite"]?.toString() ??
                                  'N/A'),
                          const Divider(),
                          _buildRowInfo("Prix d'achat :",
                              "${productDetails!["prixu"]?.toString() ?? '0'} \$"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _commanderViaWhatsApp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green[600],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.shopping_cart, color: Colors.white),
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
                      height: 360, // Height adjusted for two rows
                      child: GridView.builder(
                        physics:
                            const NeverScrollableScrollPhysics(), // Disable scrolling for GridView itself
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Two items per row
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                          childAspectRatio: 0.8, // Adjust as needed
                        ),
                        itemCount: recentProducts.length,
                        itemBuilder: (context, index) {
                          final product = recentProducts[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailproduitUser(
                                    product["id_produit"].toString(),
                                    product["designation"].toString(),
                                    product["prixu"].toString(),
                                    product["image"].toString(),
                                  ),
                                ),
                              );
                            },
                            child: SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product["image"] ?? '',
                                      height: 100,
                                      width: 140,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 100,
                                        width: 140,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image,
                                            size: 40, color: Colors.grey),
                                      ),
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
                                  Text("${product["prixu"] ?? '0'} \$"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ],
              ),
            ),
    );
  }

  /// Helper widget to build a row of information.
  Widget _buildRowInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(fontSize: 16, color: Colors.black87)),
      ],
    );
  }
}