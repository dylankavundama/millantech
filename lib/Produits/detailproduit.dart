import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/HomeScreenBar.dart';
import '../ip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProductScreen extends StatefulWidget {
  final ProductDetail product; // The product to be edited

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for the form
  late TextEditingController _designationController;
  late TextEditingController _detailController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

  bool _isSaving = false; // To show loading indicator during save

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current product data
    _designationController =
        TextEditingController(text: widget.product.designation);
    _detailController = TextEditingController(text: widget.product.detail);
    _quantityController =
        TextEditingController(text: widget.product.quantite.toString());
    _priceController =
        TextEditingController(text: widget.product.prixu.toStringAsFixed(2));
    _imageUrlController = TextEditingController(text: widget.product.imageUrl);
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _designationController.dispose();
    _detailController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // Function to handle product update
  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing
    }

    setState(() {
      _isSaving = true;
    });

    final url =
        "$Adress_IP/PRODUIT/updateproduit.php"; // Adjust to your update API endpoint
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          "id_produit": widget.product.idProduit,
          "designation": _designationController.text,
          "detail": _detailController.text,
          "quantite": _quantityController.text,
          "prixu": _priceController.text,
          "image": _imageUrlController
              .text, // Assuming image URL can be updated this way
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody["success"] == true) {
          // Assuming your PHP returns {"success": true} on success
          _showSnackBar("Produit mis à jour avec succès !");
          Navigator.pop(context, true); // Pop with true to indicate success
        } else {
          _showSnackBar(
              "Échec de la mise à jour: ${responseBody["message"] ?? "Erreur inconnue"}");
        }
      } else {
        _showSnackBar("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar(
          "Erreur de connexion: Impossible de mettre à jour le produit.");
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le produit"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _designationController,
                decoration: const InputDecoration(labelText: "Désignation"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer une désignation.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailController,
                decoration:
                    const InputDecoration(labelText: "Détail / Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: "Quantité"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer une quantité.";
                  }
                  if (int.tryParse(value) == null) {
                    return "Veuillez entrer un nombre entier valide.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Prix Unitaire"),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer un prix.";
                  }
                  if (double.tryParse(value) == null) {
                    return "Veuillez entrer un nombre décimal valide.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                    labelText: "URL de l'image (facultatif)"),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _updateProduct,
                      icon: const Icon(Icons.save),
                      label: const Text("Enregistrer les modifications"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  String code;
  String desigantion;

  Detailproduit(this.code, this.desigantion, {super.key});

  @override
  State<Detailproduit> createState() => _DetailproduitState();
}

class _DetailproduitState extends State<Detailproduit> {
  ProductDetail? _productDetail;
  bool _isLoading = true;
  String? _errorMessage;
  bool isTechnician = false;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
    _getRole();
  }

  Future<void> _getRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isTechnician = prefs.getBool('isTechnician') ?? false;
    });
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

  Future<void> _deleteProduct() async {
    var url = "$Adress_IP/PRODUIT/deleteproduit.php";
    try {
      final response =
          await http.post(Uri.parse(url), body: {"id_produit": widget.code});

      if (response.statusCode == 200) {
        _showSnackBar("Produit supprimé avec succès !");
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => const HomeBarAdmin()),
          (Route<dynamic> route) => false,
        );
      } else {
        _showSnackBar("Erreur lors de la suppression: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Erreur de connexion: Impossible de supprimer le produit.");
    }
  }

  void _showSnackBar(String description) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(description),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: Center(
            widthFactor: 1.0,
            child: Text(
              "Êtes-vous sûr de vouloir supprimer ${widget.desigantion} ?",
              textAlign: TextAlign.center,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Supprimer"),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct();
              },
            ),
          ],
        );
      },
    );
  }

  // --- NEW: Function to navigate to EditProductScreen ---
  void _navigateToEditProduct() async {
    if (_productDetail == null) {
      _showSnackBar("Impossible de modifier: Détails du produit non chargés.");
      return;
    }

    // Use push to go to the edit screen and await its result
    final bool? result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => EditProductScreen(product: _productDetail!),
      ),
    );

    // If result is true, it means the product was updated, so refresh details
    if (result == true) {
      _fetchProductDetails();
    }
  }
  // --- END NEW ---

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
            child: Text(
              value,
              textAlign: TextAlign.end,
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
          // --- NEW: Edit Button ---
          if (!isTechnician) // Only show edit button if not a technician
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEditProduct,
              tooltip: "Modifier le produit",
              color: Colors.blue, // Distinct color for edit
            ),
          // --- END NEW ---

          if (!isTechnician)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(),
              tooltip: "Supprimer le produit",
              color: Colors.redAccent,
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
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 20),
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
                                    borderRadius: BorderRadius.circular(12),
                                    child: _productDetail!.imageUrl != null &&
                                            _productDetail!.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            _productDetail!.imageUrl!,
                                            fit: BoxFit.cover,
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
                                    fontSize: 26,
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
                              const Divider(height: 30, thickness: 1),
                              _buildDetailRow("Quantité actuelle :",
                                  _productDetail!.quantite.toString()),
                              _buildDetailRow("Prix d'achat actuel :",
                                  "${_productDetail!.prixu.toStringAsFixed(2)} \$"),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}
