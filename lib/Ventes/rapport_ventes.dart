import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/ip.dart';

class RapportVentes extends StatefulWidget {
  const RapportVentes({Key? key}) : super(key: key);

  @override
  State<RapportVentes> createState() => _RapportVentesState();
}

class _RapportVentesState extends State<RapportVentes> {
  List<Map<String, dynamic>> _ventes = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterType = 'Tous';
  DateTime? _selectedDay;
  DateTime? _selectedMonth;

  double _totalVentes = 0;
  int _nombreVentes = 0;
  double _moyenneVente = 0;

  List<Map<String, dynamic>> get _filteredVentes {
    if (_filterType == 'Jour' && _selectedDay != null) {
      return _ventes.where((v) {
        final date = DateTime.tryParse(v['date_vente'] ?? '') ?? DateTime(2000);
        return date.year == _selectedDay!.year &&
            date.month == _selectedDay!.month &&
            date.day == _selectedDay!.day;
      }).toList();
    } else if (_filterType == 'Mois' && _selectedMonth != null) {
      return _ventes.where((v) {
        final date = DateTime.tryParse(v['date_vente'] ?? '') ?? DateTime(2000);
        return date.year == _selectedMonth!.year &&
            date.month == _selectedMonth!.month;
      }).toList();
    }
    return _ventes;
  }

  void _calculateStats() {
    final filtered = _filteredVentes;
    _nombreVentes = filtered.length;
    _totalVentes = filtered.fold(0.0, (sum, vente) {
      double montant = double.tryParse(vente['montant_total']?.toString() ?? '0') ?? 0;
      return sum + montant;
    });
    _moyenneVente = _nombreVentes > 0 ? _totalVentes / _nombreVentes : 0;
  }

  @override
  void initState() {
    super.initState();
    _fetchVentes();
  }

  Future<void> _fetchVentes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('$Adress_IP/VENTE/getvente.php'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Structure des données de ventes: $data');
        
        List<Map<String, dynamic>> ventesAvecTotal = [];
        
        for (var vente in data) {
          try {
            final detailResponse = await http.post(
              Uri.parse('$Adress_IP/DETAILVENTE/Get.php'),
              body: {"id": vente['id_vente'].toString()},
            );
            
            if (detailResponse.statusCode == 200) {
              final List<dynamic> details = jsonDecode(detailResponse.body);
              double totalVente = 0;
              
              for (var detail in details) {
                totalVente += double.tryParse(detail['prix_total']?.toString() ?? '0') ?? 0;
              }
              
              vente['montant_total'] = totalVente;
              ventesAvecTotal.add(Map<String, dynamic>.from(vente));
            } else {
              vente['montant_total'] = 0;
              ventesAvecTotal.add(Map<String, dynamic>.from(vente));
            }
          } catch (e) {
            print('Erreur lors du calcul du total pour la vente ${vente['id_vente']}: $e');
            vente['montant_total'] = 0;
            ventesAvecTotal.add(Map<String, dynamic>.from(vente));
          }
        }
        
        setState(() {
          _ventes = ventesAvecTotal;
          _isLoading = false;
        });
        _calculateStats();
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

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques des Ventes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Ventes',
                    '\$${_totalVentes.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Nombre Ventes',
                    _nombreVentes.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Moyenne',
                    '\$${_moyenneVente.toStringAsFixed(2)}',
                    Icons.analytics,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rapport des Ventes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchVentes,
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
                const Text('Filtrer par : ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
                          _calculateStats();
                        });
                      }
                    } else if (value == 'Mois') {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _selectedMonth ?? DateTime(now.year, now.month),
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
                          _calculateStats();
                        });
                      }
                    } else {
                      setState(() {
                        _filterType = value!;
                        _selectedDay = null;
                        _selectedMonth = null;
                        _calculateStats();
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
                    child: Text(
                        '${_selectedMonth!.month.toString().padLeft(2, '0')}/${_selectedMonth!.year}'),
                  ),
              ],
            ),
          ),
          _buildStatsCard(),
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
                              onPressed: _fetchVentes,
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
                    : _filteredVentes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Aucune vente disponible',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchVentes,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredVentes.length,
                              itemBuilder: (context, index) {
                                final vente = _filteredVentes[index];
                                
                                double montant = double.tryParse(vente['montant_total']?.toString() ?? '0') ?? 0;

                                String dateVente = '';
                                if (vente['date_vente'] != null) {
                                  dateVente = vente['date_vente'].toString();
                                } else if (vente['date'] != null) {
                                  dateVente = vente['date'].toString();
                                } else if (vente['created_at'] != null) {
                                  dateVente = vente['created_at'].toString();
                                }

                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Colors.green.withOpacity(0.1),
                                      child: const Icon(
                                        Icons.shopping_cart,
                                        color: Colors.green,
                                      ),
                                    ),
                                    title: Text(
                                      'Vente #${vente['id_vente'] ?? vente['id'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Client: ${vente['client'] ?? vente['nom_client'] ?? 'N/A'}',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Date: ${_formatDate(dateVente)}',
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${montant.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const Text(
                                          'Montant',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
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