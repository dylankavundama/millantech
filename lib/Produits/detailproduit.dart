import 'dart:convert';
import 'dart:io'; // Maintenu car présent dans votre code initial, même si inutilisé pour le détail produit seul
import 'package:flutter/cupertino.dart'; // Maintenu pour CupertinoPageRoute
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/HomeScreenBar.dart';
import '../ip.dart'; // Assurez-vous que ce chemin est correct et que 'Adress_IP' est défini.
import 'package:shared_preferences/shared_preferences.dart';

// Modèle pour les détails du produit
class ProductDetail {
  final String idProduit;
  final String designation;
  final String? detail;
  final int quantite;
  final double prixu;
  final String? imageUrl;

  ProductDetail({
    required this.idProduit,
    required this.designation,
    this.detail,
    required this.quantite,
    required this.prixu,
    this.imageUrl,
  });

  // Factory constructor pour créer une instance depuis un JSON
  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      idProduit: json["id_produit"].toString(),
      designation: json["designation"].toString(),
      detail: json["detail"]?.toString(),
      quantite: int.tryParse(json["quantite"]?.toString() ?? '0') ?? 0,
      prixu: double.tryParse(json["prixu"]?.toString() ?? '0.0') ?? 0.0,
      imageUrl: json["image"]?.toString(),
    );
  }
}

// ignore: must_be_immutable
class Detailproduit extends StatefulWidget {
  // Renommés pour la clarté, mais conservés comme variables de classe pour correspondre à la structure.
  String code;
  String desigantion;

  Detailproduit(this.code, this.desigantion, {super.key});

  @override
  State<Detailproduit> createState() => _DetailproduitState();
}

class _DetailproduitState extends State<Detailproduit> {
  // Variables d'état
  // File? _image; // Supprimé car non utilisé dans cette page (insertion d'image)

  // Variables pour la gestion des données produit
  ProductDetail? _productDetail;
  bool _isLoading = true;
  String? _errorMessage;
  bool isTechnician = false;

  // @override
  // void initState() {
  //   super.initState();
  //   getrecord(); // Inutilisé pour cette page, donc supprimé de l'initialisation
  //   getrecords(); // Remplacé par _fetchProductDetails
  // }

  @override
  void initState() {
    super.initState();
    _fetchProductDetails(); // Appel pour charger les détails du produit
    _getRole();
  }

  Future<void> _getRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isTechnician = prefs.getBool('isTechnician') ?? false;
    });
  }

  // Fonctions de l'API (adaptées et renommées pour la clarté)

  // Ancienne fetchdata() pour mouvement, non utilisée dans ce contexte de détail produit, donc non incluse.
  // Future<List<Map<String, dynamic>>> fetchdata() async { /* ... */ }

  // savadatas() pour l'insertion, non utilisée dans cette page de détail, donc non incluse.
  // Future<void> savadatas() async { /* ... */ }

  // getrecord() pour les catégories, non utilisée dans cette page, donc non incluse.
  // Future<void> getrecord() async { /* ... */ }

  // Remplace getrecords() avec une gestion d'état améliorée
  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Réinitialiser les messages d'erreur précédents
    });

    final url = "$Adress_IP/PRODUIT/gettrie.php";
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {"id": widget.code},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _productDetail = ProductDetail.fromJson(data[0]);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Aucun détail de produit trouvé.";
            _isLoading = false;
          });
          _showSnackBar("Aucun détail de produit trouvé.");
        }
      } else {
        setState(() {
          _errorMessage = "Erreur serveur: ${response.statusCode}";
          _isLoading = false;
        });
        _showSnackBar(
            "Erreur lors du chargement des détails: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de connexion: $e";
        _isLoading = false;
      });
      _showSnackBar(
          "Erreur de connexion: Impossible de charger les détails du produit.");
    }
  }

  // Remplace delrecord()
  Future<void> _deleteProduct() async {
    var url = "$Adress_IP/PRODUIT/deleteproduit.php";
    try {
      final response =
          await http.post(Uri.parse(url), body: {"id_produit": widget.code});

      if (response.statusCode == 200) {
        _showSnackBar("Produit supprimé avec succès !");
        // Naviguer vers l'écran d'accueil après suppression réussie
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => const HomeBarAdmin()),
          (Route<dynamic> route) =>
              false, // Supprime toutes les routes précédentes
        );
      } else {
        _showSnackBar("Erreur lors de la suppression: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Erreur de connexion: Impossible de supprimer le produit.");
    }
  }

  // Remplace bar()
  void _showSnackBar(String description) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(description),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Méthode pour afficher la boîte de dialogue de confirmation de suppression
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          // Contenu centré dans la boîte de dialogue
          content: Center(
            widthFactor:
                1.0, // Permet au Center de prendre toute la largeur disponible
            child: Text(
              "Êtes-vous sûr de vouloir supprimer ${widget.desigantion} ?",
              textAlign: TextAlign.center, // Centre le texte lui-même
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Supprimer"),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                _deleteProduct(); // Procéder à la suppression
              },
            ),
          ],
        );
      },
    );
  }

  // Widget utilitaire pour afficher les lignes de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          Flexible(
            // Utiliser Flexible pour éviter les débordements de texte long
            child: Text(
              value,
              textAlign: TextAlign.end, // Aligner le texte à droite
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.desigantion),
        actions: [
          if (!isTechnician)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(), // Appel de la confirmation
              tooltip: "Supprimer le produit",
              color:
                  Colors.redAccent, // Couleur distinctive pour la suppression
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _productDetail == null
                    ? const Center(
                        child: Text("Détails du produit introuvables."))
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(
                              16.0), // Padding général plus généreux
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      bottom: 20), // Marge en bas de l'image
                                  // Ajustement de la largeur et hauteur pour une meilleure adaptabilité
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 3,
                                          blurRadius: 10,
                                          offset: const Offset(0, 3))
                                    ],
                                  ),
                                  child: ClipRRect(
                                    // Pour que l'image respecte le BorderRadius
                                    borderRadius: BorderRadius.circular(12),
                                    child: _productDetail!.imageUrl != null &&
                                            _productDetail!.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            _productDetail!.imageUrl!,
                                            fit: BoxFit
                                                .cover, // Mieux pour les images
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                  Icons.broken_image,
                                                  size: 80,
                                                  color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                                Icons.image_not_supported,
                                                size: 80,
                                                color: Colors.grey),
                                          ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Text(
                                  _productDetail!.designation,
                                  style: const TextStyle(
                                    fontSize:
                                        26, // Taille de police légèrement augmentée
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Text(
                                  _productDetail!.detail ??
                                      "Pas de description détaillée.",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[700]),
                                ),
                              ),
                              const Divider(
                                  height: 30,
                                  thickness: 1), // Ligne de séparation
                              _buildDetailRow("Quantité actuelle :",
                                  _productDetail!.quantite.toString()),
                              _buildDetailRow("Prix d'achat actuel :",
                                  "${_productDetail!.prixu.toStringAsFixed(2)} \$"),
                              // Vous pouvez ajouter d'autres lignes de détail ici si nécessaire
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}
