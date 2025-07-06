import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pp;
// import 'package:pdf/pdf.dart';
import 'package:stocktrue/Produits/mobile.dart';
import 'package:stocktrue/ip.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';

import '../Achats/Listdetail.dart';

// ignore: must_be_immutable
class Lisventedet extends StatefulWidget {
  String code;
  String client;
  Lisventedet(
    
    this.client,
    this.code, {super.key});

  @override
  State<Lisventedet> createState() => _LisventedetState();
}

class _LisventedetState extends State<Lisventedet> {
  TextEditingController codevente = TextEditingController();
  TextEditingController codeproduit = TextEditingController();
  TextEditingController quantite = TextEditingController();
  TextEditingController prixu = TextEditingController();
  List<Achatdetail> clients = [];
  Map<String, dynamic> once = {};

  // String adress = currentip();
  List data = [];
  // ignore: prefer_typing_uninitialized_variables
  var selectedname;
  // ignore: prefer_typing_uninitialized_variables
  var selectedvalue;
  // ignore: prefer_typing_uninitialized_variables
  var seleccat;
  late Future<List<Map<String, dynamic>>> _data;

  List _datas = [];
  Future<void> fetchdataS() async {
    final response = await http.post(
        Uri.parse('$Adress_IP/DETAILVENTE/Get.php'),
        body: {"id": widget.code});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _datas = data;
        print(_datas);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<List<Map<String, dynamic>>> fetchdata() async {
    final response = await http.post(
        Uri.parse('$Adress_IP/DETAILVENTE/Get.php'),
        body: {"id": widget.code});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _datas = data;
      });
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _createPDF(
      {String? date, required String nom, String? code}) async {
    print('Impression PDF déclenchée');

    // 🔹 Générer la date et le numéro si non fournis
    date ??= DateFormat('dd/MM/yyyy').format(DateTime.now());
    code ??= 'F-${DateTime.now().millisecondsSinceEpoch}';

    // 🔹 Données produits
    List<Map<String, dynamic>> data = await fetchdata();

    // 🔹 Création du document PDF
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final Size pageSize = page.getClientSize();
    final PdfGraphics graphics = page.graphics;

    final PdfFont titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
    final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

    double top = 0;

    // 🔹 Logo (assurez-vous que l'image est dans pubspec.yaml)
    final ByteData bytes = await rootBundle.load('assets/logo.png');
    final Uint8List imageData = bytes.buffer.asUint8List();
    final PdfBitmap logo = PdfBitmap(imageData);

    graphics.drawImage(logo, const Rect.fromLTWH(0, 0, 100, 100));

    // 🔹 Coordonnées de l'entreprise
    graphics.drawString(
      'PRO CLEANERS\n60 Faubourg Saint Honoré\n75116 Paris\nFrance\nprocleaners@live.com',
      contentFont,
      bounds: const Rect.fromLTWH(110, 0, 250, 100),
    );

    // 🔹 Infos client
// ...
    graphics.drawString(
      'FACTURÉ À $nom\n82 rue Sadi Carnot\n75116 Paris\nFrance',
      contentFont,
      bounds: Rect.fromLTWH(pageSize.width - 200, 0, 200, 100),
    );
// ...

    top += 120;

    // 🔹 Détails de la facture
    graphics.drawString(
      'Facture N° : $code\nDate : $date\nÉchéance : 14 jours\nDate de livraison : $date',
      contentFont,
      bounds: Rect.fromLTWH(0, top, 300, 80),
    );

    top += 90;

    // 🔹 Titre principal
    graphics.drawString(
      'FACTURE',
      titleFont,
      bounds: Rect.fromLTWH(pageSize.width / 2 - 50, top, 200, 40),
    );

    top += 50;

    // 🔹 Tableau des produits
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 4);
    grid.headers.add(1);

    final PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Produits';
    header.cells[1].value = 'Quantité';
    header.cells[2].value = 'Prix U (€)';
    header.cells[3].value = 'PT (€)';

    double total = 0;

    for (final item in data) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = item['produit'];
      row.cells[1].value = item['quantite'].toString();
      row.cells[2].value = item['prixu'].toString();
      row.cells[3].value = item['prix_total'].toString();

      total += double.tryParse(item['prix_total'].toString()) ?? 0;
    }

    // 🔹 Style global du tableau
    grid.style = PdfGridStyle(
      font: PdfStandardFont(PdfFontFamily.helvetica, 12),
      cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
    );

    // 🔹 Style des cellules d’en-tête
    for (int i = 0; i < header.cells.count; i++) {
      final cell = header.cells[i];
      cell.style.backgroundBrush = PdfBrushes.lightGray;
      cell.style.textBrush = PdfBrushes.black;
      cell.style.font = PdfStandardFont(PdfFontFamily.helvetica, 14,
          style: PdfFontStyle.bold);
    }

    // 🔹 Affichage du tableau
    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, top, pageSize.width, 0),
    );

    // 🔹 Montant total
    graphics.drawString(
      'MONTANT TOTAL (EUR): €${total.toStringAsFixed(2)}',
      PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, top + 150, 400, 30),
    );

    // 🔹 Sauvegarde et impression
    final Uint8List bytesFinal = Uint8List.fromList(await document.save());
    document.dispose();

    await Printing.layoutPdf(
      onLayout: (pp.PdfPageFormat format) async => bytesFinal,
    );
  }

  void sms(String ms) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ms),
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  void initState() {
    super.initState();
    _data = fetchdata();
    fetchdataS();
    getrecord();
  }

  Future<void> savadatas() async {
    var url = "$Adress_IP/DETAILVENTE/insertdetailvente.php";
    // var t="http://192.168.215.182/API_VENTE/DETAILAPPROVISIONNEMENT/postapp.php";
    Uri ulr = Uri.parse(url);
    var request = http.MultipartRequest('POST', ulr);
    request.fields['vente_id'] = widget.code;
    request.fields['produit_id'] = selectedname;
    request.fields['quantite'] = quantite.text;
    request.fields['prixu'] = prixu.text;
    var res = await request.send();
    var response = await http.Response.fromStream(res);
    if (response.statusCode == 200) {
      // showToast(msg: "Succès !");
      fetchdataS();
      setState(() {
        _data = fetchdata();
      });
    } else {
      print("error");
    }
    // ignore: use_build_context_synchronously
    Navigator.pop(
      context,
    );
  }

  Future<void> getrecord() async {
    var url = "$Adress_IP/PRODUIT/getproduit.php";
    try {
      var response = await http.get(Uri.parse(url));
      setState(() {
        data = jsonDecode(response.body);
        print(data);
      });
    } catch (e) {
      print(e);
    }
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
                  "Details de la vente",
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
                        code:
                            null, // ou tu peux supprimer ce champ pour générer automatiquement
                      );
                    },
                    icon: const Icon(Icons.print)),
                IconButton(
                    onPressed: () {
                      // showModalBottomSheet(

                      //   context: context, builder: (context)=>ModalShow(widget.code));
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10.0),
                                height: 500,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: ListView(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          const Text(
                                            "Ajouter plus de detail",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w300),
                                          ),
                                          const SizedBox(
                                            height: 25,
                                          ),
                                          DropdownButtonFormField(
                                            // hint: const Text("Select client"),
                                            //  if(){}
                                            items: data.map((list) {
                                              if (data.isEmpty) {
                                                // return Circ;
                                              }
                                              return DropdownMenuItem(
                                                value: list["id_produit"],
                                                child:
                                                    Text(list["designation"]),
                                              );
                                            }).toList(),
                                            //onChanged: onChanged,

                                            value: selectedvalue,
                                            icon: const Icon(
                                                Icons.arrow_drop_down_circle),
                                            decoration: const InputDecoration(
                                                prefixIcon: Icon(Icons
                                                    .production_quantity_limits),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(10)),
                                                  borderSide: BorderSide(
                                                      color: Colors.orange),
                                                ),
                                                hintText: "Produit",
                                                labelText: "Produit"),
                                            onChanged: (value) {
                                              selectedvalue = value;
                                              // client=selectedvalue;
                                              setState(() {
                                                selectedname = value.toString();
                                              });

                                              print(selectedname);
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: quantite,
                                            decoration: const InputDecoration(
                                                prefixIcon: Icon(Icons
                                                    .production_quantity_limits_rounded),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(10)),
                                                  borderSide: BorderSide(
                                                      color: Colors.orange),
                                                ),
                                                hintText: "Quantite",
                                                labelText: "Quantite"),
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: prixu,
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
                                                labelText: "Prix"),
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
                                                const SizedBox(
                                                  width: 15,
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      if (quantite
                                                              .text.isEmpty ||
                                                          prixu.text.isEmpty) {
                                                        sms("Completer tous les champs");
                                                      } else {
                                                        // int t=in
                                                        if (int.parse(quantite
                                                                    .text) <=
                                                                0 ||
                                                            int.parse(prixu
                                                                    .text) <=
                                                                0) {
                                                          sms("Entrer des valeurs superieurs");
                                                        } else {
                                                          savadatas();
                                                          setState(() {
                                                            _data = fetchdata();
                                                          });
                                                        }
                                                      }
                                                    });
                                                  },
                                                  child: const Text('Vendre'),
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
                          });
                    },
                    icon: const Icon(Icons.add_circle_outline_outlined)),
              ],
            ),
          ),
          FutureBuilder(
              future: _data,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data!;
                  return DataTable(
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
                        )),
                        DataColumn(
                            label: Text("Quantite",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 150, 138, 6)))),
                        DataColumn(
                            label: Text("Prix",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 150, 138, 6)))),
                        DataColumn(
                            label: Text("PT",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 150, 138, 6))))
                      ],
                      rows: data
                          .map((item) => DataRow(cells: [
                                DataCell(Text(item['produit'])),
                                DataCell(Text(item['quantite'].toString())),
                                DataCell(Text(item['prixu'].toString())),
                                DataCell(Text(item['prix_total'].toString()))
                              ]))
                          .toList());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return const CircularProgressIndicator();
              })
        ],
      ),
    );
  }
}

// Fonction utilitaire pour sauvegarder et ouvrir le PDF
Future<void> saveAndLaunchFile(List<int> bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = directory.path;
  final file = File('$path/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  print('Sauvegarde du PDF à : $path/$fileName');
  await OpenFile.open(file.path);
}
