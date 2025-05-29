import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/Util.dart';
import 'package:stocktrue/Ventes/ListdetVente.dart';
import 'package:stocktrue/Ventes/report.dart';
import '../ip.dart';

class Ventes extends StatefulWidget {
  const Ventes({super.key});

  @override
  State<Ventes> createState() => _VentesState();
}

class _VentesState extends State<Ventes> {
  Future<void> getrecords() async {
    var url = "$Adress_IP/CLIENT/getclient.php";
    try {
      var response = await http.get(Uri.parse(url));
      setState(() {
        d = jsonDecode(response.body);
        // bar("Success");
        print(d);
      });
    } catch (e) {
      print(e);
    }
  }

  List data = [];
  var selectedvalue;
  var selectedname;
  List d = [];
  // String adress = currentip();
  Future<void> getrecord() async {
    var url = "$Adress_IP/VENTE/getvente.php";
    try {
      var response = await http.get(Uri.parse(url));
      setState(() {
        data = jsonDecode(response.body);
        print(data);
      });
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

  @override
  void initState() {
    // TODO: implement initState
    getrecord();
    getrecords();
    super.initState();
  }

  double screenheigth = 0;
  double screenwith = 0;
  @override
  Widget build(BuildContext context) {
    screenwith = MediaQuery.of(context).size.width;
    screenheigth = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          // centerTitle: true,
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => report()));
                },
                icon: const Icon(Icons.file_download_done_outlined))
          ],
          title: const AppTitle()),
      body: ListView.builder(
        itemCount: data.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14.0),
              padding: const EdgeInsets.all(0.0),
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 1.0,
                    spreadRadius: 0.0,
                    color: Colors.transparent,
                  )
                ],
              ),
              child: Card(
                elevation: 0.5,
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Lisventedet(data[index]["id_vente"].toString()),
                      ),
                    );
                  },
                  title: Text(
                    data[index]["client"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  leading: Text(
                    "${index + 1}. ",
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.insert_drive_file_sharp,
                            color: Color.fromARGB(255, 11, 92, 23)),
                        onPressed: () {
                          // Action de modification ou affichage modal
                          setState(() {
                            // Ajoute ici ce que tu veux faire
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text(
                                  "Voulez-vous vraiment supprimer ?"),
                              actions: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        print(data[index]["id_vente"]);
                                        delrecord(
                                            data[index]["id_vente"].toString());
                                        setState(() {
                                          Navigator.pop(context);
                                        });
                                      },
                                      child: const Text("Effectuer"),
                                    )
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      height: 230,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListView(
                        children: [
                          const Text(
                            "Faire un Achat",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          DropdownButtonFormField(
                            // hint: const Text("Select client"),
                            //  if(){}
                            items: d.map((list) {
                              if (d.isEmpty) {
                                // return Circ;
                              }
                              return DropdownMenuItem(
                                value: list["id_client"],
                                child: Text(list["noms"]),
                              );
                            }).toList(),
                            //onChanged: onChanged,

                            value: selectedvalue,
                            icon: const Icon(Icons.arrow_drop_down_circle),
                            decoration: const InputDecoration(
                                prefixIcon:
                                    Icon(Icons.production_quantity_limits),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                hintText: "Client",
                                labelText: "Client"),
                            onChanged: (value) {
                              selectedvalue = value;
                              // client=selectedvalue;
                              setState(() {
                                selectedname = value.toString();
                              });

                              // Object? selectedname;
                              print(selectedname);
                            },
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.save_alt_outlined,
                              color: Colors.black,
                            ),
                            label: const Text(
                              "Save",
                              style: TextStyle(color: Colors.black),
                            ),
                            onPressed: () {
                              savadatas();
                              setState(() {
                                Navigator.pop(context);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              // elevation: 0,
                              backgroundColor:
                                  const Color.fromARGB(255, 227, 174, 131),
                              // fixedSize: const Size(60, 45),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        ],
                      ),
                    ));
              });
        },
        // backgroundColor: Colors.orange[900],
        disabledElevation: 10,
        child: const Icon(
          Icons.add,
          // color: Colors.white,
        ),
      ),
    );
  }

  Future<void> delrecord(var id) async {
    try {
      var url = "$Adress_IP/VENTE/deletevente.php";
      String newid = id.toString();
      var result = await http.post(Uri.parse(url), body: {
        "id": newid.toString(),
      });
      var reponse = jsonDecode(result.body);
      getrecord();
      if (reponse["Success"] == "Succes") {
        print("record deleted");
        debugPrint("");
        getrecord();
      } else {
        bar("Success");
        print("Success de suppression");
        getrecord();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> savadatas() async {
    try {
      var url = "$Adress_IP/VENTE/insertvente.php";
      Uri ulr = Uri.parse(url);
      var request = http.MultipartRequest('POST', ulr);
      request.fields['client_id'] = selectedname;
      var res = await request.send();
      var response = await http.Response.fromStream(res);

      if (response.statusCode == 200) {
        bar("Success insert");
        getrecord();
      } else {
        bar("Error insert");
      }
    } catch (e) {
      bar(e.toString());
      print(e);
    }
  }
}
