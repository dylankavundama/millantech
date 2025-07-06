import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/Produits/detailproduit.dart';
import 'package:stocktrue/ip.dart';
import 'Add_product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Allproduct extends StatefulWidget {
  const Allproduct({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AllproductState createState() => _AllproductState();
}

class _AllproductState extends State<Allproduct> {
  List dataens = [];
  bool isLoading = true;
  bool isTechnician = false;
  String? _errorMessage;
  // String adress = currentip();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _getRole();
  }

  Future<void> _getRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isTechnician = prefs.getBool('isTechnician') ?? false;
    });
  }

  Future<void> fetchProducts() async {
    final url = "$Adress_IP/PRODUIT/getproduit.php";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          dataens = jsonDecode(response.body);
          isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          isLoading = false;
          _errorMessage = "Erreur serveur : \\${response.statusCode}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _errorMessage = "Erreur de connexion : $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  Color _getStockColor(int quantite) {
    return quantite < 4 ? Colors.red : Colors.green;
  }

  IconData _getStockIcon(int quantite) {
    return quantite < 4 ? Icons.warning : Icons.check_circle;
  }

  String _getStockStatus(int quantite) {
    return quantite < 4 ? 'Stock Faible' : 'Stock OK';
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
                : dataens.isEmpty
                    ? const Center(child: Text("Aucun produit trouvé."))
                    : ListView.builder(
                        itemCount: dataens.length,
                        itemBuilder: (context, index) {
                          final produit = dataens[index];
                          final imageUrl = (produit["image"] ?? "").toString();
                          final quantite = int.tryParse(produit["quantite"]?.toString() ?? '0') ?? 0;
                          final stockColor = _getStockColor(quantite);
                          final stockIcon = _getStockIcon(quantite);
                          final stockStatus = _getStockStatus(quantite);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Detailproduit(
                                    produit["id_produit"].toString(),
                                    produit["designation"].toString(),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              height: 200,
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 35,
                                    child: Material(
                                      elevation: 4.0,
                                      borderRadius: BorderRadius.circular(16.0),
                                      child: Container(
                                        height: 165.0,
                                        width: width * 0.91,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.15),
                                              offset: const Offset(0.0, 2.0),
                                              blurRadius: 12.0,
                                              spreadRadius: 2.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 10,
                                    child: Card(
                                      elevation: 10.0,
                                      shadowColor: Colors.grey.withOpacity(0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15.0),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10.0),
                                        child: imageUrl.isEmpty
                                            ? Container(
                                                height: 170,
                                                width: 140,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                                              )
                                            : Image.network(
                                                imageUrl,
                                                height: 170,
                                                width: 140,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  height: 170,
                                                  width: 140,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 45,
                                    left: height * 0.22,
                                    child: SizedBox(
                                      height: 200,
                                      width: 150,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            produit["designation"],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Divider(color: Colors.orange),
                                          Row(
                                            children: [
                                              Icon(
                                                stockIcon,
                                                color: stockColor,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Quantité: $quantite",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: stockColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(top: 2, bottom: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: stockColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              stockStatus,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: stockColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "Prix: \\${produit["prixu"]} \$",
                                            style: const TextStyle(fontSize: 17, color: Colors.grey),
                                          ),
                                          Text(
                                            "Type: \\${produit["categorie"]}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color.fromARGB(255, 102, 101, 101),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Divider(color: Colors.orange),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: isTechnician
          ? null
          : Tooltip(
              message: "Ajouter un produit",
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) =>   AddProduct()));
                },
                disabledElevation: 10,
                child: const Icon(Icons.add),
              ),
            ),
    );
  }
}
