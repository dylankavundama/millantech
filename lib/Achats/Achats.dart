// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/Achats/Listdetail.dart';
import 'package:stocktrue/Util.dart';

import '../ip.dart';

class Achats extends StatefulWidget {
  const Achats({super.key});

  @override
  State<Achats> createState() => _AchatsState();
}

class _AchatsState extends State<Achats> {
  DateTime date = DateTime.now();
  String text = "";
  TextEditingController dateone = TextEditingController();
  // String adress = currentip();
  var selectedvalue;
  var selectedname;
  List data = [];
  String status = '';

  Future<void> delrecord(var id) async {
    try {
      var url =
          "$Adress_IP/APPROVISIONNEMNT/deleteapprovisionnement.php";
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

  Future<void> getrecord() async {
    var url =
        "$Adress_IP/APPROVISIONNEMNT/getapprovisionnement.php";
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

  List d = [];
  Future<void> getrecords() async {
    var url = "$Adress_IP/FOURNISSEUR/getfournisseur.php";
    try {
      var response = await http.get(Uri.parse(url));
      setState(() {
        d = jsonDecode(response.body);
        print(d);
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  initState() {
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
      appBar: AppBar(actions: [
        IconButton(
            onPressed: () {
              showAboutDialog(context: context);
            },
            icon: const Icon(Icons.info_outline))
      ], title: const AppTitle()),
      body: ListView.builder(
          itemCount: data.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return data.isEmpty
                ? const CircularProgressIndicator()
                : Padding(
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
                                builder: (context) => Listdetail(
                                  data[index]["id_approvisionnement"]
                                      .toString(),
                                ),
                              ),
                            );
                          },
                          title: Text(
                            data[index]["fournisseur"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                showDialog(
                                  context: context,
                                  builder: (context) => buildEditDialog(index),
                                );
                              } else if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text(
                                        "Voulez-vous vraiment supprimer ?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          delrecord(data[index]
                                              ["id_approvisionnement"]);
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Effectuer"),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Modifier')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Supprimer')),
                            ],
                          ),
                          leading: Text(
                            "${index + 1}. ",
                            style: const TextStyle(fontWeight: FontWeight.w400),
                          ),
                          subtitle: Text(data[index]["date_approvisionnement"]),
                        ),
                      ),
                    ),
                  );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigator.push(context, MaterialPageRoute(builder: (context)=>const Addventes()));
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      height: 320,
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
                                value: list["id_fournisseur"],
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
                                hintText: "Fournisseur",
                                labelText: "Fournisseur"),
                            onChanged: (value) {
                              selectedvalue = value;
                              // client=selectedvalue;
                              setState(() {
                                selectedname = value.toString();
                              });

                              print(selectedname);
                            },
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 10, bottom: 10, left: 10),
                            child: TextField(
                              controller: dateone,
                              decoration: const InputDecoration(
                                labelText: "Date de l'achat",
                                filled: true,
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.green),
                                  //borderRadius:
                                ),
                                //fillColor: Colors.green,
                                focusColor: Colors.green,

                                // hoverColor: Colors.green
                              ),
                              readOnly: true,
                              onTap: () {
                                _selected(dateone);
                              },
                            ),
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
          color: Colors.black,
        ),
      ),
    );
  }

  var app;
  Future<void> updatedatas(String va, String v) async {
    try {
      var url =
          "$Adress_IP/APPROVISIONNEMNT/updateapprovisionnement.php";
      Uri ulr = Uri.parse(url);
      var request = http.MultipartRequest('POST', ulr);
      request.fields['id_approvionnement'] = va;
      request.fields['fournisseur_id'] = "7";
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

  Future<void> savadatas() async {
    try {
      var url =
          "$Adress_IP/APPROVISIONNEMNT/insertapprovisionnement.php";
      Uri ulr = Uri.parse(url);
      var request = http.MultipartRequest('POST', ulr);
      request.fields['fournisseur_id'] = selectedname;
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

  void bar(String description) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(description),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selected(TextEditingController date) async {
    DateTime? _picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));

    if (_picked != null) {
      setState(() {
        date.text = _picked.toString().split(" ")[0];
      });
    } else {
      setState(() {
        date.text = "2024-29-9";
      });
    }
  }

  Widget buildEditDialog(int index) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ListView(
          children: [
            const Text(
              "Edit un achat",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            DropdownButtonFormField(
              items: d.map((list) {
                return DropdownMenuItem(
                  value: list["id_fournisseur"],
                  child: Text(list["noms"]),
                );
              }).toList(),
              value: selectedvalue,
              icon: const Icon(Icons.arrow_drop_down_circle),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.production_quantity_limits),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                hintText: "Fournisseur",
                labelText: "Fournisseur",
              ),
              onChanged: (value) {
                selectedvalue = value;
                setState(() {
                  selectedname = value.toString();
                });
              },
            ),
            const SizedBox(height: 25),
            TextField(
              controller: dateone,
              decoration: const InputDecoration(
                labelText: "Date de l'achat",
                prefixIcon: Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () {
                _selected(dateone);
              },
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined, color: Colors.black),
              label: const Text("Edit", style: TextStyle(color: Colors.black)),
              onPressed: () {
                updatedatas(data[index]["id_approvisionnement"], selectedname);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 227, 174, 131),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
