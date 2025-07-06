import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/Produits/detailproduit.dart';
import 'package:stocktrue/ip.dart';
import 'Add_product.dart';

class Allproduct extends StatefulWidget {
  const Allproduct({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AllproductState createState() => _AllproductState();
}

class _AllproductState extends State<Allproduct> {
  List dataens = [];
  bool isLoading = true;
  // String adress = currentip();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final url = "$Adress_IP/PRODUIT/getproduit.php";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          dataens = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("Erreur serveur : ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Erreur de connexion : $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : dataens.isEmpty
                ? const Center(child: Text("Aucun produit trouvé."))
                : ListView.builder(
                    itemCount: dataens.length,
                    itemBuilder: (context, index) {
                      final produit = dataens[index];
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
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          height: 200,
                          child: Stack(
                            children: [
                              Positioned(
                                top: 35,
                                child: Material(
                                  elevation: 0.0,
                                  child: Container(
                                    height: 165.0,
                                    width: width * 0.91,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          offset: const Offset(0.0, 0.0),
                                          blurRadius: 20.0,
                                          spreadRadius: 4.0,
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
                                  child: Container(
                                    height: 170,
                                    width: 140,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      image: DecorationImage(
                                        fit: BoxFit.fill,
                                        image: NetworkImage(
                                          // "$Adress_IP/PRODUIT/images/${produit["image"]}",
                                             "${produit["image"]}",
                                        ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        produit["designation"],
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const Divider(color: Colors.orange),
                                      Text(
                                        "Quantité: ${produit["quantite"]}",
                                        style: const TextStyle(
                                            fontSize: 15, color: Colors.black),
                                      ),
                                      Text(
                                        "Prix: ${produit["prixu"]} \$",
                                        style: const TextStyle(
                                            fontSize: 17, color: Colors.grey),
                                      ),
                                      Text(
                                        "Type: ${produit["categorie"]}",
                                        style: const TextStyle(
                                          fontSize: 17,
                                          color: Color.fromARGB(
                                              255, 102, 101, 101),
                                        ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) =>   AddProduct()));
        },
        disabledElevation: 10,
        child: const Icon(Icons.add),
      ),
    );
  }
}
