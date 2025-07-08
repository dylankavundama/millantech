import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/ip.dart'; // Assurez-vous que ce fichier existe et contient Adress_IP

// Modèle pour les détails d'achat
class Achatdetail {
  final int codevente;
  final int codeproduit;
  final int quantite;
  final double prixu;

  Achatdetail({
    required this.codeproduit,
    required this.quantite,
    required this.codevente,
    required this.prixu,
  });

  Map<String, dynamic> toJson() {
    return {
      'vente_id': codevente,
      'produit_id': codeproduit,
      'quantite': quantite,
      'prixu': prixu,
    };
  }
}

class AddVenDetail extends StatefulWidget {
  final String idvente; // Rendre idvente final car il ne change pas
  const AddVenDetail(this.idvente, {super.key});

  @override
  State<AddVenDetail> createState() => _AddVenDetailState();
}

class _AddVenDetailState extends State<AddVenDetail> {
  // Contrôleurs de texte
  final TextEditingController quantiteController = TextEditingController();
  final TextEditingController prixuController = TextEditingController();

  // Liste des articles ajoutés au panier
  List<Achatdetail> cartItems = [];

  // Données des produits récupérées depuis l'API
  List<dynamic> productData = [];

  // ID du produit sélectionné dans le Dropdown
  String? selectedProductId;

  // Stock du produit actuellement sélectionné
  int selectedProductStock = 0;

  @override
  void initState() {
    super.initState();
    _loadProductsAndCheckStock();
  }

  @override
  void dispose() {
    quantiteController.dispose();
    prixuController.dispose();
    super.dispose();
  }

  /// Charge les produits depuis l'API et effectue une vérification initiale du stock.
  Future<void> _loadProductsAndCheckStock() async {
    setState(() {
      productData = []; // Réinitialise la liste avant le chargement
    });
    try {
      var url = "$Adress_IP/PRODUIT/getproduit.php";
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> fetchedData = jsonDecode(response.body);

        // Filtre les produits pour n'afficher que ceux avec un stock supérieur à 0
        final availableProducts = fetchedData.where((product) {
          int stock = int.tryParse(product["quantite"].toString()) ?? 0;
          return stock > 0;
        }).toList();

        if (availableProducts.isEmpty) {
          if (mounted) {
            _showErrorDialog(
              "Stock insuffisant",
              "Aucun produit n'est en stock. Impossible d'ajouter un détail de vente.",
              shouldPop: true,
            );
          }
        } else {
          setState(() {
            productData = availableProducts;
            // Si un seul produit est disponible, le présélectionner
            if (productData.length == 1) {
              selectedProductId = productData.first["id_produit"].toString();
              _updateProductDetails(productData.first);
            }
          });
        }
      } else {
        if (mounted) {
          _showSnackBar(
              "Erreur lors du chargement des produits: ${response.statusCode}");
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des produits: $e'); // Pour le débogage
      if (mounted) {
        _showSnackBar("Erreur de connexion: $e");
      }
    }
  }

  /// Met à jour les champs de texte du prix et le stock sélectionné
  /// en fonction du produit choisi dans le Dropdown.
  void _updateProductDetails(Map<String, dynamic> product) {
    if (product["prix"] != null) {
      prixuController.text = product["prix"].toString();
    } else {
      prixuController.clear();
    }
    selectedProductStock = int.tryParse(product["quantite"].toString()) ?? 0;
  }

  /// Affiche un SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Affiche un AlertDialog
  Future<void> _showErrorDialog(String title, String content,
      {bool shouldPop = false}) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Ferme le dialogue
              if (shouldPop && mounted) {
                Navigator.pop(context); // Ferme la page actuelle
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Ajoute le produit sélectionné au panier après validation.
  void _addItemToCart() {
    if (selectedProductId == null) {
      _showSnackBar("Veuillez sélectionner un produit.");
      return;
    }

    final int? quantity = int.tryParse(quantiteController.text);
    if (quantity == null || quantity <= 0) {
      _showSnackBar("Veuillez entrer une quantité valide.");
      return;
    }

    final double? unitPrice = double.tryParse(prixuController.text);
    if (unitPrice == null || unitPrice <= 0) {
      _showSnackBar("Veuillez entrer un prix valide.");
      return;
    }

    if (selectedProductStock == 0) {
      _showSnackBar("Stock épuisé pour ce produit.");
      return;
    }

    // NOUVELLE LOGIQUE : Vérifie si la quantité est INFÉRIEURE au stock
    // Et ferme la page si cette condition est remplie.
    if (quantity < selectedProductStock) {
      _showErrorDialog(
        "Quantité trop faible",
        "La quantité saisie ($quantity) est inférieure au stock disponible ($selectedProductStock). Veuillez ajuster.",
        shouldPop: true, // Ceci fermera la page AddVenDetail
      );
      return; // Arrête l'ajout au panier
    }

    // LOGIQUE EXISTANTE : Vérifie si la quantité est SUPÉRIEURE au stock
    if (quantity > selectedProductStock) {
      _showSnackBar(
          "Stock insuffisant. Stock disponible : $selectedProductStock");
      return;
    }

    // Vérifier si le produit est déjà dans le panier et mettre à jour la quantité
    final existingItemIndex = cartItems
        .indexWhere((item) => item.codeproduit.toString() == selectedProductId);

    setState(() {
      if (existingItemIndex != -1) {
        // Mise à jour de la quantité si le produit existe déjà
        final existingItem = cartItems[existingItemIndex];
        final newQuantity = existingItem.quantite + quantity;

        if (newQuantity > selectedProductStock) {
          _showSnackBar(
              "Vous avez déjà ${existingItem.quantite} dans le panier. L'ajout de $quantity dépasserait le stock disponible ($selectedProductStock).");
          return;
        }

        cartItems[existingItemIndex] = Achatdetail(
          codeproduit: existingItem.codeproduit,
          quantite: newQuantity,
          codevente: existingItem.codevente,
          prixu: existingItem.prixu,
        );
      } else {
        // Ajout d'un nouvel article au panier
        cartItems.add(Achatdetail(
          codeproduit: int.parse(selectedProductId!),
          quantite: quantity,
          prixu: unitPrice,
          codevente: int.parse(widget.idvente),
        ));
      }

      // Effacer seulement le champ quantité après l'ajout
      quantiteController.clear();
    });

    _showSnackBar("Article ajouté au panier.");
  }

  /// Enregistre la vente (simulation)
  void _recordSale() {
    if (cartItems.isEmpty) {
      _showSnackBar("Aucun article dans le panier pour enregistrer la vente.");
      return;
    }

    // Ici, vous enverriez `cartItems` à votre API
    List jsonCart = cartItems.map((e) => e.toJson()).toList();
    print("Vente à enregistrer: $jsonCart"); // Pour le débogage

    // TODO: Implémenter la logique d'envoi à l'API et de mise à jour du stock
    _showSnackBar("Vente enregistrée avec succès! (Simulation)");
    if (mounted) {
      Navigator.of(context).pop(); // Ferme la page après l'enregistrement
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouvelle Vente"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedProductId,
              items: productData.map((product) {
                // Le filtrage initial a déjà retiré les produits sans stock
                // donc ici tous les produits listés ont un stock > 0.
                return DropdownMenuItem<String>(
                  value: product["id_produit"].toString(),
                  child: Text(product["designation"]),
                );
              }).toList(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.production_quantity_limits),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: Colors.orange),
                ),
                hintText: "Produit",
                labelText: "Produit",
              ),
              onChanged: (String? newValue) {
                setState(() {
                  selectedProductId = newValue;
                  if (newValue != null) {
                    final selectedProduct = productData.firstWhere(
                      (p) => p["id_produit"].toString() == newValue,
                      orElse: () => {}, // Fournir une Map vide si non trouvé
                    );
                    _updateProductDetails(selectedProduct);
                  } else {
                    prixuController.clear();
                    quantiteController.clear();
                    selectedProductStock = 0;
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantiteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.production_quantity_limits_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: Colors.orange),
                ),
                hintText: "Quantité",
                labelText: "Quantité",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: prixuController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.monetization_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: Colors.orange),
                ),
                hintText: "Prix de l'article",
                labelText: "Prix",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addItemToCart,
              child: const Text('Ajouter au panier'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recordSale,
              child: const Text('Enregistrer la vente'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(
                      child: Text("Votre panier est vide."),
                    )
                  : ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final product = productData.firstWhere(
                          (p) =>
                              p["id_produit"].toString() ==
                              item.codeproduit.toString(),
                          orElse: () => {"designation": "Produit inconnu"},
                        );
                        final productName = product["designation"];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(productName),
                            subtitle: Text(
                                "Qté: ${item.quantite} | Prix U: ${item.prixu} | Total: ${item.quantite * item.prixu}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  cartItems.removeAt(index);
                                });
                                _showSnackBar("Article retiré du panier.");
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
