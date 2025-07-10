import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pp;
import 'package:stocktrue/ip.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Import dropdown_search

import '../Achats/Listdetail.dart'; // Assurez-vous que Achatdetail est défini ici

// ignore: must_be_immutable
class Lisventedet extends StatefulWidget {
  String code;
  String client;
  Lisventedet(this.client, this.code, {super.key});

  @override
  State<Lisventedet> createState() => _LisventedetState();
}

class _LisventedetState extends State<Lisventedet> {
  // Contrôleurs de texte
  final TextEditingController quantiteController = TextEditingController();
  final TextEditingController prixuController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _futureSaleDetails;

  // Données des produits (pour le Dropdown et la vérification de stock)
  Map<String, dynamic> _productsMap = {};
  List<dynamic> _productsListForDropdown = [];

  // ID du produit sélectionné dans le Dropdown
  String? selectedProductId;
  int _currentSelectedProductStock = 0;

  // Nouvelle variable pour gérer l'état de chargement du bouton "Vendre"
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _futureSaleDetails = _fetchSaleDetails();
    _loadProducts();
  }

  @override
  void dispose() {
    quantiteController.dispose();
    prixuController.dispose();
    super.dispose();
  }

  /// Récupère les détails de la vente depuis l'API.
  Future<List<Map<String, dynamic>>> _fetchSaleDetailsData() async {
    final response = await http.post(
      Uri.parse('$Adress_IP/DETAILVENTE/Get.php'),
      body: {"id": widget.code},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          'Échec du chargement des détails de vente: ${response.statusCode}');
    }
  }

  /// Initialise ou Rafraîchit le Future pour le FutureBuilder.
  Future<List<Map<String, dynamic>>> _fetchSaleDetails() {
    return _fetchSaleDetailsData();
  }

  /// Récupère la liste de tous les produits depuis l'API
  /// et les stocke pour le Dropdown et la vérification de stock.
  Future<void> _loadProducts() async {
    var url = "$Adress_IP/PRODUIT/getproduit.php";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> fetchedData = jsonDecode(response.body);
        setState(() {
          _productsListForDropdown = fetchedData.where((product) {
            int stock = int.tryParse(product["quantite"].toString()) ?? 0;
            return stock > 0;
          }).toList();

          _productsMap.clear();
          for (var product in fetchedData) {
            _productsMap[product["id_produit"].toString()] = product;
          }

          // If a product was selected but is now out of stock or removed, clear selection
          if (selectedProductId != null &&
              (!_productsMap.containsKey(selectedProductId) ||
                  int.tryParse(_productsMap[selectedProductId]!["quantite"]
                          .toString()) ==
                      0)) {
            selectedProductId = null;
            prixuController.clear();
            quantiteController.clear();
            _currentSelectedProductStock = 0;
          } else if (selectedProductId != null &&
              _productsMap.containsKey(selectedProductId)) {
            _updateProductDetailsFromSelection(
                _productsMap[selectedProductId]!);
          }
          // No need to auto-select the first product if none is selected,
          // let the user explicitly select one using the search feature.
        });
      } else {
        _showSnackBar(
            "Erreur lors du chargement des produits: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Erreur de connexion lors du chargement des produits: $e");
    }
  }

  /// Met à jour les champs de texte du prix et le stock sélectionné
  /// en fonction du produit choisi dans le Dropdown.
  void _updateProductDetailsFromSelection(Map<String, dynamic> product) {
    prixuController.text = product["prix"]?.toString() ?? '';
    _currentSelectedProductStock =
        int.tryParse(product["quantite"].toString()) ?? 0;
  }

  /// Affiche un SnackBar
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Affiche un AlertDialog
  Future<void> _showAlertDialog(String title, String content) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Enregistre les nouveaux détails de vente et met à jour le stock.
  Future<void> _saveNewSaleDetail() async {
    // Empêche les clics multiples pendant le chargement
    if (_isLoading) return;

    // Démarre le chargement
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Validation des champs d'entrée
      if (selectedProductId == null || selectedProductId!.isEmpty) {
        _showSnackBar("Veuillez sélectionner un produit.");
        return; // Sortir avant de changer l'état de chargement si erreur
      }

      final int? quantity = int.tryParse(quantiteController.text);
      if (quantity == null || quantity <= 0) {
        _showSnackBar("Veuillez entrer une quantité valide (> 0).");
        return;
      }

      final double? unitPrice = double.tryParse(prixuController.text);
      if (unitPrice == null || unitPrice <= 0) {
        _showSnackBar("Veuillez entrer un prix valide (> 0).");
        return;
      }

      // 2. Vérification du stock
      final selectedProduct = _productsMap[selectedProductId];
      if (selectedProduct == null) {
        _showSnackBar("Produit sélectionné introuvable.");
        return;
      }

      final int availableStock =
          int.tryParse(selectedProduct["quantite"].toString()) ?? 0;

      if (availableStock == 0) {
        await _showAlertDialog(
            "Stock Épuisé", "Ce produit est actuellement en rupture de stock.");
        return;
      }

      if (quantity > availableStock) {
        await _showAlertDialog("Stock Insuffisant",
            "La quantité demandée ($quantity) dépasse le stock disponible ($availableStock) pour ce produit.");
        return;
      }

      // 3. Envoi des données à l'API
      var url = "$Adress_IP/DETAILVENTE/insertdetailvente.php";
      Uri ulr = Uri.parse(url);
      var request = http.MultipartRequest('POST', ulr);
      request.fields['vente_id'] = widget.code;
      request.fields['produit_id'] = selectedProductId!;
      request.fields['quantite'] = quantiteController.text;
      request.fields['prixu'] = prixuController.text;

      var res = await request.send();
      var response = await http.Response.fromStream(res);

      if (response.statusCode == 200) {
        _showSnackBar("Détail de vente ajouté avec succès !");
        setState(() {
          _futureSaleDetails =
              _fetchSaleDetails(); // Rafraîchit le FutureBuilder
        });
        await _loadProducts(); // Rafraîchit les stocks du dropdown
        if (mounted) {
          Navigator.pop(context); // Ferme le dialogue
        }
      } else {
        await _showAlertDialog(
            "Erreur", "Échec de l'ajout du détail de vente: ${response.body}");
      }
    } catch (e) {
      await _showAlertDialog(
          "Erreur de connexion", "Impossible de contacter le serveur: $e");
    } finally {
      // S'assure que le loader est désactivé même en cas d'erreur
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Génère et affiche la facture PDF.
  Future<void> _createPDF(
      {String? date, required String nom, String? code}) async {
    print('Impression PDF déclenchée');

    date ??= DateFormat('dd/MM/yyyy').format(DateTime.now());
    code ??= 'F-${DateTime.now().millisecondsSinceEpoch}';

    List<Map<String, dynamic>> data = await _fetchSaleDetailsData();

    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final Size pageSize = page.getClientSize();
    final PdfGraphics graphics = page.graphics;

    final PdfFont titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
    final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

    double top = 0;

    final ByteData bytes = await rootBundle.load('assets/logo.png');
    final Uint8List imageData = bytes.buffer.asUint8List();
    final PdfBitmap logo = PdfBitmap(imageData);
    graphics.drawImage(logo, const Rect.fromLTWH(0, 0, 100, 100));

    graphics.drawString(
      'MillanTech\nBoulevard de libération\nBâtiment de la poste \n+243 819 782 016\nBunia',
      contentFont,
      bounds: const Rect.fromLTWH(110, 0, 250, 100),
    );

    graphics.drawString(
      'FACTURÉ À $nom\nBunia\nBoulevard de libération',
      contentFont,
      bounds: Rect.fromLTWH(pageSize.width - 200, 0, 200, 100),
    );

    top += 120;

    graphics.drawString(
      'Facture N° : $code\nDate : $date\nÉchéance : 14 jours\nDate de livraison : $date',
      contentFont,
      bounds: Rect.fromLTWH(0, top, 300, 80),
    );

    top += 90;

    graphics.drawString(
      'FACTURE',
      titleFont,
      bounds: Rect.fromLTWH(pageSize.width / 2 - 50, top, 200, 40),
    );

    top += 50;

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 4);
    grid.headers.add(1);

    final PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Produits';
    header.cells[1].value = 'Quantité';
    header.cells[2].value = 'Prix U (\$)';
    header.cells[3].value = 'PT (\$)';

    double total = 0;

    for (final item in data) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = item['produit'];
      row.cells[1].value = item['quantite'].toString();
      row.cells[2].value = item['prixu'].toString();
      row.cells[3].value = item['prix_total'].toString();

      total += double.tryParse(item['prix_total'].toString()) ?? 0;
    }

    grid.style = PdfGridStyle(
      font: PdfStandardFont(PdfFontFamily.helvetica, 12),
      cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
    );

    for (int i = 0; i < header.cells.count; i++) {
      final cell = header.cells[i];
      cell.style.backgroundBrush = PdfBrushes.lightGray;
      cell.style.textBrush = PdfBrushes.black;
      cell.style.font = PdfStandardFont(PdfFontFamily.helvetica, 14,
          style: PdfFontStyle.bold);
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, top, pageSize.width, 0),
    );

    graphics.drawString(
      'MONTANT TOTAL (USD): ${total.toStringAsFixed(2)} \$',
      PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, top + 150, 400, 30),
    );

    final Uint8List bytesFinal = Uint8List.fromList(await document.save());
    document.dispose();

    await Printing.layoutPdf(
      onLayout: (pp.PdfPageFormat format) async => bytesFinal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Détails de la vente",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    String now =
                        DateFormat('dd/MM/yyyy').format(DateTime.now());
                    _createPDF(
                      date: now,
                      nom: widget.client,
                      code: widget.code,
                    );
                  },
                  icon: const Icon(Icons.print),
                ),
                IconButton(
                  onPressed: () {
                    // Clear controllers and selected product before showing dialog
                    quantiteController.clear();
                    prixuController.clear();
                    selectedProductId = null;
                    _currentSelectedProductStock = 0;

                    _loadProducts().then((_) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          // Use StatefulBuilder to manage the dialog's internal state
                          return StatefulBuilder(
                            builder: (BuildContext context,
                                StateSetter setDialogState) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  height:
                                      500, // May need adjustment based on content
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: ListView(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize
                                              .min, // Use min to fit content
                                          children: [
                                            const Text(
                                              "Ajouter plus de détail",
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w300),
                                            ),
                                            const SizedBox(height: 25),
                                            // --- DropdownSearch for Products ---
                                            DropdownSearch<
                                                Map<String, dynamic>>(
                                              popupProps: PopupProps.menu(
                                                showSearchBox: true,
                                                searchFieldProps:
                                                    TextFieldProps(
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText:
                                                        "Rechercher un produit...",
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.fromLTRB(
                                                            12, 12, 8, 0),
                                                  ),
                                                ),
                                                itemBuilder: (context, product,
                                                    isSelected) {
                                                  return ListTile(
                                                    title: Text(product[
                                                            "designation"] ??
                                                        "Produit inconnu"),
                                                    subtitle: Text(
                                                        "Stock: ${product["quantite"] ?? 0}"),
                                                  );
                                                },
                                              ),
                                              dropdownDecoratorProps:
                                                  DropDownDecoratorProps(
                                                dropdownSearchDecoration:
                                                    const InputDecoration(
                                                  labelText: "Produit",
                                                  hintText:
                                                      "Sélectionner un produit",
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.fromLTRB(
                                                          12, 12, 8, 0),
                                                ),
                                              ),
                                              items: _productsListForDropdown
                                                  .cast<Map<String, dynamic>>(),
                                              itemAsString: (Map<String,
                                                          dynamic>
                                                      product) =>
                                                  "${product["designation"]} (${product["quantite"] ?? 0})",
                                              selectedItem: _productsMap.values
                                                  .firstWhere(
                                                (p) =>
                                                    p["id_produit"]
                                                        .toString() ==
                                                    selectedProductId,
                                                orElse: () => null,
                                              ) as Map<String, dynamic>?,
                                              onChanged: (Map<String, dynamic>?
                                                  newValue) {
                                                setDialogState(() {
                                                  // Use setDialogState to update dialog's UI
                                                  selectedProductId =
                                                      newValue?["id_produit"]
                                                          .toString();
                                                  if (newValue != null) {
                                                    _updateProductDetailsFromSelection(
                                                        newValue);
                                                  } else {
                                                    prixuController.clear();
                                                    quantiteController.clear();
                                                    _currentSelectedProductStock =
                                                        0;
                                                  }
                                                });
                                              },
                                            ),
                                            // --- End DropdownSearch ---

                                            const SizedBox(height: 15),

                                            TextField(
                                              controller: quantiteController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                prefixIcon: const Icon(Icons
                                                    .production_quantity_limits_rounded),
                                                border:
                                                    const OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(10)),
                                                  borderSide: BorderSide(
                                                      color: Colors.orange),
                                                ),
                                                hintText: "Quantité",
                                                labelText:
                                                    "Quantité (Dispo: $_currentSelectedProductStock)", // Show available stock
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            TextField(
                                              controller: prixuController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                prefixIcon:
                                                    Icon(Icons.monetization_on),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(10)),
                                                  borderSide: BorderSide(
                                                      color: Colors.orange),
                                                ),
                                                hintText: "Prix de l'article",
                                                labelText: "Prix",
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 5.0, left: 5),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const SizedBox(width: 15),
                                                  ElevatedButton(
                                                    onPressed: _isLoading
                                                        ? null
                                                        : () {
                                                            _saveNewSaleDetail()
                                                                .then((_) {
                                                              // After saving, re-fetch products to ensure stock is updated in the dialog
                                                              setDialogState(
                                                                  () {
                                                                // Update dialog's state
                                                                _loadProducts();
                                                              });
                                                            });
                                                          }, // Wrap in a function to re-load products after save
                                                    child: _isLoading
                                                        ? const SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                        : const Text('Vendre'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline_outlined),
                ),
              ],
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureSaleDetails,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Aucun détail de vente trouvé.'));
              } else {
                final data = snapshot.data!;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    horizontalMargin: 20,
                    columns: const [
                      DataColumn(
                        label: Text(
                          "Produit",
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 150, 138, 6)),
                        ),
                      ),
                      DataColumn(
                        label: Text("Quantité",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 150, 138, 6))),
                      ),
                      DataColumn(
                        label: Text("Prix",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 150, 138, 6))),
                      ),
                      DataColumn(
                        label: Text("PT",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 150, 138, 6))),
                      )
                    ],
                    rows: data
                        .map((item) => DataRow(cells: [
                              DataCell(Text(item['produit'] ?? '')),
                              DataCell(
                                  Text(item['quantite']?.toString() ?? '')),
                              DataCell(Text(item['prixu']?.toString() ?? '')),
                              DataCell(
                                  Text(item['prix_total']?.toString() ?? ''))
                            ]))
                        .toList(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<void> saveAndLaunchFile(List<int> bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = directory.path;
  final file = File('$path/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  print('Sauvegarde du PDF à : $path/$fileName');
  await OpenFile.open(file.path);
}
