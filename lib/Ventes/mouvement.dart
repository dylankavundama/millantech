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
  List<Map<String, dynamic>> _mouvements = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterType = 'Tous';
  DateTime? _selectedDay;
  DateTime? _selectedMonth;

  List<Map<String, dynamic>> get _filteredMouvements {
    if (_filterType == 'Jour' && _selectedDay != null) {
      return _mouvements.where((m) {
        final date = DateTime.tryParse(m['dateoperation'] ?? '') ?? DateTime(2000);
        return date.year == _selectedDay!.year && date.month == _selectedDay!.month && date.day == _selectedDay!.day;
      }).toList();
    } else if (_filterType == 'Mois' && _selectedMonth != null) {
      return _mouvements.where((m) {
        final date = DateTime.tryParse(m['dateoperation'] ?? '') ?? DateTime(2000);
        return date.year == _selectedMonth!.year && date.month == _selectedMonth!.month;
      }).toList();
    }
    return _mouvements;
  }

  @override
  void initState() {
    super.initState();
    _fetchMouvements();
  }

  Future<void> _fetchMouvements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.easykivu.com/phonexa/MOUVEMENT/getmouvementstock.php'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _mouvements = data.map((item) => Map<String, dynamic>.from(item)).toList();
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  Color _getOperationColor(String typeOperation) {
    switch (typeOperation.toUpperCase()) {
      case 'SORTIE':
        return Colors.red;
      case 'ENTREE':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getOperationIcon(String typeOperation) {
    switch (typeOperation.toUpperCase()) {
      case 'SORTIE':
        return Icons.remove_circle_outline;
      case 'ENTREE':
        return Icons.add_circle_outline;
      default:
        return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mouvements de Stock',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchMouvements,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Trier par : ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterType,
                  items: const [
                    DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                    DropdownMenuItem(value: 'Jour', child: Text('Jour')),
                    DropdownMenuItem(value: 'Mois', child: Text('Mois')),
                  ],
                  onChanged: (value) async {
                    if (value == 'Jour') {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDay ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _filterType = value!;
                          _selectedDay = picked;
                        });
                      }
                    } else if (value == 'Mois') {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedMonth ?? DateTime(now.year, now.month),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        helpText: 'Sélectionnez un mois',
                        fieldLabelText: 'Mois/Année',
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null) {
                        setState(() {
                          _filterType = value!;
                          _selectedMonth = DateTime(picked.year, picked.month);
                        });
                      }
                    } else {
                      setState(() {
                        _filterType = value!;
                        _selectedDay = null;
                        _selectedMonth = null;
                      });
                    }
                  },
                ),
                if (_filterType == 'Jour' && _selectedDay != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(_formatDate(_selectedDay!.toIso8601String())),
                  ),
                if (_filterType == 'Mois' && _selectedMonth != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('${_selectedMonth!.month.toString().padLeft(2, '0')}/${_selectedMonth!.year}'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
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
                              onPressed: _fetchMouvements,
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
                    : _filteredMouvements.isEmpty
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
                                  'Aucun mouvement de stock disponible',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchMouvements,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredMouvements.length,
                              itemBuilder: (context, index) {
                                final mouvement = _filteredMouvements[index];
                                final typeOperation = mouvement['type_operation'] ?? '';
                                final operationColor = _getOperationColor(typeOperation);
                                final operationIcon = _getOperationIcon(typeOperation);

                                return Card(
                                  elevation: 4,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: operationColor.withOpacity(0.1),
                                      child: Icon(
                                        operationIcon,
                                        color: operationColor,
                                        size: 24,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            mouvement['produit'] ?? 'Produit inconnu',
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
                                            color: operationColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            typeOperation,
                                            style: TextStyle(
                                              color: operationColor,
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
                                            const Icon(Icons.shopping_cart, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Quantité: \\${mouvement['quantite']}',
                                              style: const TextStyle(color: Colors.grey),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Prix: \\${mouvement['prixu']}',
                                              style: const TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Date: \\${_formatDate(mouvement['dateoperation'] ?? '')}',
                                              style: const TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
} 