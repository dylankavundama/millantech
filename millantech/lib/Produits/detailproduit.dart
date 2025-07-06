import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
 
import 'package:stocktrue/HomeScreenBar.dart';
import 'package:stocktrue/Produits/mobile.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../ip.dart';

// ignore: must_be_immutable
class Detailproduit extends StatefulWidget {
  String code;
  String desigantion;
  Detailproduit(this.code, this.desigantion, {super.key});

  @override
  State<Detailproduit> createState() => _DetailproduitState();
}

class _DetailproduitState extends State<Detailproduit> {
  File? _image;
  // String adress = currentip();

  Future<List<Map<String, dynamic>>> fetchdata() async {
    final response = await http.post(
      Uri.parse('$Adress_IP/MOUVEMENT/getmv.php'),
      body: {"id": widget.code},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _createPDF(String date, String nom, String code) async {
    List m = await fetchdata();
    PdfDocument document = PdfDocument();
    final page = document.pages.add();

    PdfGrid grid = PdfGrid();
    grid.style = PdfGridStyle(
      font: PdfStandardFont(PdfFontFamily.helvetica, 15),
      cellPadding: PdfPaddings(left: 2, right: 2, top: 2, bottom: 2),
    );

    grid.columns.add(count: 5);
    grid.headers.add(1);

    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Type';
    header.cells[1].value = 'Date';
    header.cells[2].value = 'Quantite';
    header.cells[3].value = 'Prix u';
    header.cells[4].value = 'PT';

    for (Map<String, dynamic> item in m) {
      PdfGridRow row = grid.rows.add();
      row.cells[0].value = item['type_operation'].toString();
      row.cells[1].value = item['dateoperation'].toString();
      row.cells[2].value = item['quantite'].toString();
      row.cells[3].value = item['prixu'].toString();
      row.cells[4].value = item['pt'].toString();
    }

    page.graphics.drawString(
      'Fiche de stock: $code\nNom: $nom\nDate: $date',
      PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
    );

    grid.style = PdfGridStyle(
      cellPadding: PdfPaddings(left: 0, right: 0, top: 4, bottom: 2),
      backgroundBrush: PdfBrushes.blanchedAlmond,
      textBrush: PdfBrushes.black,
      font: PdfStandardFont(PdfFontFamily.timesRoman, 15),
    );

    grid.draw(
      page: document.pages.add(),
      bounds: const Rect.fromLTWH(10, 0, 0, 0),
    );

    List<int> bytes = await document.save();
    document.dispose();

    saveAndLaunchFile(bytes, 'Fiche.pdf');
  }

  // ignore: prefer_typing_uninitialized_variables
  var selectedvalue;
  // ignore: prefer_typing_uninitialized_variables
  var selectedname;
  TextEditingController nom = TextEditingController();
  List d = [];
  List dataens = [];

  Future<void> savadatas() async {
    try {
      var url = "$Adress_IP/PRODUIT/insertproduit.php";
      Uri ulr = Uri.parse(url);
      var request = http.MultipartRequest('POST', ulr);
      request.fields['designation'] = nom.text;
      request.fields['categorie_id'] = "1";
      request.files.add(http.MultipartFile.fromBytes(
          'image1', File(_image!.path).readAsBytesSync(),
          filename: _image!.path));
      var res = await request.send();
      var response = await http.Response.fromStream(res);

      if (response.statusCode == 200) {
        bar("Success insert");
      } else {
        bar("Error insert");
      }
    } catch (e) {
      bar(e.toString());
    }
  }

  void bar(String description) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(description),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> getrecord() async {
    var url = "$Adress_IP/CATEGORIEPROD/getcategorie.php";
    try {
      var response = await http.get(Uri.parse(url));
      setState(() {
        d = jsonDecode(response.body);
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> getrecords() async {
    var url = "$Adress_IP/PRODUIT/gettrie.php";
    final response = await http.post(Uri.parse(url), body: {"id": widget.code});
    if (response.statusCode == 200) {
      setState(() {
        dataens = jsonDecode(response.body) as List;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> delrecord() async {
    var url = "$Adress_IP/PRODUIT/deleteproduit.php";
    final response =
        await http.post(Uri.parse(url), body: {"id_produit": widget.code});
    if (response.statusCode == 200) {
      print("Success delete");
    } else {
      throw Exception('Failed to delete data');
    }
  }

  @override
  void initState() {
    getrecord();
    getrecords();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.desigantion),
      ),
      body: SafeArea(
        child: dataens.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.all(11),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          width: MediaQuery.of(context).size.height * 0.65,
                          height: MediaQuery.of(context).size.height * 0.90,
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
                          child: Column(
                            children: [
                              const SizedBox(height: 5),
                              Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  image: DecorationImage(
                                    fit: BoxFit.fill,
                                    image: NetworkImage(
                                      // "$Adress_IP/PRODUIT/images/${dataens[0]["image"]}",
                                             "${dataens[0]["image"]}",
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  dataens[0]["designation"].toString(),
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(dataens[0]["detail"]?.toString() ??
                                    "Pas de detail"),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Quantité actuelle :"),
                                  Text(dataens[0]["quantite"].toString()),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Prix d'achat actuel :"),
                                  Text("${dataens[0]["prixu"].toString()} \$"),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                 
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      delrecord();
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) =>
                                                  HomeBarAdmin()),
                                        (Route<dynamic> route) => false,
                                      );
                                    },
                                    color: Colors.white,
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
