import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/ip.dart';

class MouvementStock extends StatefulWidget {
  const MouvementStock({Key? key}) : super(key: key);

  @override
  State<MouvementStock> createState() => _MouvementStockState();
}

class _MouvementStockState extends State<MouvementStock> {
  List<Map<String, dynamic>> _stocks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStocks();
  }

  Future<void> _fetchStocks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$Adress_IP/PRODUIT/getproduit.php'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _stocks = data.map((item) => Map<String, dynamic>.from(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Erreur serveur: ${response.statusCode}";
          _isLoading = false;
        });
        _showSnackBar(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de connexion: $e";
        _isLoading = false;
      });
      _showSnackBar(_errorMessage!);
    }
  }

  Future<void> _updateQuantity(String productId, String newQuantity) async {
    try {
      final response = await http.post(
        Uri.parse('$Adress_IP/PRODUIT/updatequantity.php'),
        body: {
          'id_produit': productId,
          'quantite': newQuantity,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          _showSnackBar('Quantité mise à jour avec succès');
          _fetchStocks(); // Recharger les données
        } else {
          _showSnackBar('Erreur: ${result['message'] ?? 'Erreur inconnue'}');
        }
      } else {
        _showSnackBar('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion: $e');
    }
  }

  Future<void> _showEditQuantityDialog(Map<String, dynamic> produit) async {
    final TextEditingController quantityController = TextEditingController(
      text: produit['quantite']?.toString() ?? '0',
    );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier la quantité'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Produit: ${produit['designation'] ?? 'Produit inconnu'}'),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nouvelle quantité',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newQuantity = quantityController.text.trim();
                if (newQuantity.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _updateQuantity(
                    produit['id_produit']?.toString() ?? '',
                    newQuantity,
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stock des Produits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchStocks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchStocks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _stocks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucun produit disponible',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchStocks,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stocks.length,
                        itemBuilder: (context, index) {
                          final produit = _stocks[index];
                          final quantite = int.tryParse(produit['quantite']?.toString() ?? '0') ?? 0;
                          final stockColor = _getStockColor(quantite);
                          final stockIcon = _getStockIcon(quantite);
                          final stockStatus = _getStockStatus(quantite);

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: stockColor.withOpacity(0.1),
                                child: Icon(
                                  stockIcon,
                                  color: stockColor,
                                  size: 24,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      produit['designation'] ?? 'Produit inconnu',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: stockColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      stockStatus,
                                      style: TextStyle(
                                        color: stockColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Quantité en stock: $quantite',
                                        style: TextStyle(
                                          color: stockColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                onPressed: () => _showEditQuantityDialog(produit),
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Modifier la quantité',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
} 