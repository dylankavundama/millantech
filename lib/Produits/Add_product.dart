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

  Widget _buildImagePreview() {
    final url = _imageController.text.trim();
    if (url.isEmpty) {
      return Container(
        height: imageContainerHeight,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image, size: 60, color: Colors.grey)),
      );
    }
    return Image.network(
      url,
      height: imageContainerHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        height: imageContainerHeight,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
      ),
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
                    _buildImagePreview(),
                    const SizedBox(height: fieldSpacing),
                    _buildFormField(
                      controller: _imageController,
                      labelText: 'Lien de l\'image',
                      hintText: 'https://.../image.jpg',
                      icon: Icons.image,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le lien de l\'image est obligatoire.';
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: fieldSpacing),
                    _buildFormField(
                      controller: _nameController,
                      labelText: 'Nom du produit',
                      hintText: 'Ex: Smartphone',
                      icon: Icons.label,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est obligatoire.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: fieldSpacing),
                    _buildFormField(
                      controller: _detailController,
                      labelText: 'Détail',
                      hintText: 'Description du produit',
                      icon: Icons.description,
                    ),
                    const SizedBox(height: fieldSpacing),
                    _buildFormField(
                      controller: _quantityController,
                      labelText: 'Quantité',
                      hintText: '0',
                      icon: Icons.confirmation_number,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La quantité est obligatoire.';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Entrez un nombre valide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: fieldSpacing),
                    _buildFormField(
                      controller: _priceController,
                      labelText: 'Prix unitaire',
                      hintText: '0',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le prix est obligatoire.';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Entrez un prix valide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: fieldSpacing),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['id_categorie'].toString(),
                          child: Text(cat['nom_categorie'] ?? cat['designation'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null ? 'Sélectionnez une catégorie.' : null,
                    ),
                    const SizedBox(height: fieldSpacing * 2),
                    SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton.icon(
                        icon: _isSavingProduct
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSavingProduct ? 'Enregistrement...' : 'Enregistrer'),
                        onPressed: _isSavingProduct ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
