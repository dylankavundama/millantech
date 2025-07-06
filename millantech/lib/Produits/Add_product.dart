import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/HomeScreenBar.dart';
import 'package:stocktrue/ip.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  static const double defaultPadding = 20.0;
  static const double fieldSpacing = 16.0;
  static const double imageContainerHeight = 180.0;
  static const double buttonHeight = 50.0;

  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = false;
  bool _isSavingProduct = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? _imageInputError;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _clearimage() {
    setState(() {
      _imageController.clear();
      _imageInputError = null;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Veuillez corriger les erreurs dans le formulaire.');
      return;
    }

    if (_selectedCategoryId == null) {
      _showSnackBar('Veuillez sélectionner une catégorie.');
      return;
    }

    if (_imageController.text.trim().isEmpty) {
      setState(() {
        _imageInputError = 'Le lien de l\'image est obligatoire.';
      });
      _showSnackBar('Veuillez fournir un lien d\'image.');
      return;
    }

    setState(() => _isSavingProduct = true);

    try {
      final uri = Uri.parse("https://www.easykivu.com/phonexa/PRODUIT/insertproduit.php");
      final request = http.MultipartRequest("POST", uri);

      request.fields.addAll({
        'designation': _nameController.text.trim(),
        'detail': _detailController.text.trim(),
        'categorie_id': _selectedCategoryId!,
        'quantite': _quantityController.text.trim().isEmpty ? '0' : _quantityController.text.trim(),
        'prixu': _priceController.text.trim().isEmpty ? '0' : _priceController.text.trim(),
        'image': _imageController.text.trim(),
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['status'] == 'success') {
          _showSnackBar('Produit ajouté avec succès !');
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (_) => const HomeBarAdmin()),
            (route) => false,
          );
        } else {
          throw Exception(jsonResponse['message'] ?? 'Erreur inconnue lors de l\'ajout.');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isSavingProduct = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  Future<void> _fetchCategories() async {
    if (_isLoadingCategories) return;
    setState(() => _isLoadingCategories = true);

    try {
      final response = await http.get(
        Uri.parse("$Adress_IP/CATEGORIEPROD/getcategorie.php"),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(data);
            if (_categories.isNotEmpty) {
              _selectedCategoryId = _categories.first['id_categorie'].toString();
            }
          });
        } else {
          throw Exception('Format de données inattendu.');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}.');
      }
    } catch (e) {
      _showSnackBar('Erreur lors du chargement des catégories.');
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        labelText: labelText,
        hintText: hintText,
        counterText: '',
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Produit', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormField(
                      controller: _nameController,
                      labelText: "Nom du produit*",
                      hintText: "Entrez le nom du produit",
                      icon: Icons.description,
                      maxLength: 100,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Ce champ est obligatoire.' : null,
                    ),
                    const SizedBox(height: fieldSpacing),
                    _buildFormField(
                      controller: _detailController,
                      labelText: "Détail du produit*",
                      hintText: "Entrez le détail du produit",
                      icon: Icons.info_outline,
                      maxLength: 255,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Ce champ est obligatoire.' : null,
                    ),
                    const SizedBox(height: fieldSpacing),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['id_categorie'].toString(),
                          child: Text(category['designation'] ?? 'Inconnu'),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                        labelText: "Catégorie*",
                      ),
                      onChanged: (value) => setState(() => _selectedCategoryId = value),
                      validator: (value) =>
                          value == null ? 'Veuillez sélectionner une catégorie.' : null,
                    ),
                    const SizedBox(height: fieldSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _quantityController,
                            labelText: "Quantité",
                            hintText: "0",
                            icon: Icons.inventory_2,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final num = double.tryParse(value.replaceAll(',', '.'));
                              if (num == null) return 'Quantité invalide.';
                              if (num < 0) return 'La quantité ne peut être négative.';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: fieldSpacing),
                        Expanded(
                          child: _buildFormField(
                            controller: _priceController,
                            labelText: "Prix unitaire",
                            hintText: "0",
                            icon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final num = double.tryParse(value.replaceAll(',', '.'));
                              if (num == null) return 'Prix invalide.';
                              if (num < 0) return 'Le prix ne peut être négatif.';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: fieldSpacing),
                    _buildFormField(
                      controller: _imageController,
                      labelText: "Lien de l'image*",
                      hintText: "Collez l'URL de l'image ici",
                      icon: Icons.link,
                      keyboardType: TextInputType.url,
                      onChanged: (value) => setState(() => _imageInputError = null),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Ce champ est obligatoire.';
                        final uri = Uri.tryParse(value.trim());
                        if (uri == null || !uri.hasAbsolutePath || !uri.isAbsolute) return 'URL invalide.';
                        return null;
                      },
                    ),
                    const SizedBox(height: fieldSpacing),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Aperçu de l'image", style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Container(
                          height: imageContainerHeight,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _imageInputError != null ? Colors.red : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: (_imageController.text.trim().isNotEmpty &&
                                  Uri.tryParse(_imageController.text.trim())?.isAbsolute == true)
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _imageController.text.trim(),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Center(child: Text("Erreur de chargement d'image.")),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        onPressed: _clearimage,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported,
                                        size: 50, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    const Text('Collez un lien d\'image valide pour voir l\'aperçu'),
                                  ],
                                ),
                        ),
                        if (_imageInputError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_imageInputError!, style: const TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: fieldSpacing * 2),
                    SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isSavingProduct ? null : _saveProduct,
                        child: _isSavingProduct
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Enregistrer',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
