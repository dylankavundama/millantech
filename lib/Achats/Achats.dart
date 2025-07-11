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
  var selectedvalue;
  var selectedname;
  List data = [];
  List d = []; // For suppliers data
  String status = '';
  bool _isLoading = false; // New state variable for loading

  @override
  void initState() {
    super.initState();
    _loadData(); // Call a method to load all initial data
  }

  // A helper method to load all necessary data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // Show loader
    });
    await Future.wait([
      getrecord(), // Fetch purchase records
      getrecords(), // Fetch supplier records
    ]);
    setState(() {
      _isLoading = false; // Hide loader
    });
  }

  Future<void> delrecord(var id) async {
    setState(() {
      _isLoading = true; // Show loader
    });
    try {
      var url = "$Adress_IP/APPROVISIONNEMNT/deleteapprovisionnement.php";
      String newid = id.toString();
      var result = await http.post(Uri.parse(url), body: {
        "id": newid.toString(),
      });
      var reponse = jsonDecode(result.body);

      if (reponse["Success"] == "Succes") {
        bar("Suppression réussie");
        await getrecord(); // Refresh data after deletion
      } else {
        bar("Erreur de suppression: ${reponse["Message"] ?? ""}");
      }
    } catch (e) {
      print(e);
      bar("Erreur de connexion lors de la suppression: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false; // Hide loader
      });
    }
  }

  Future<void> getrecord() async {
    var url = "$Adress_IP/APPROVISIONNEMNT/getapprovisionnement.php";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
          status = 'Success';
        });
      } else {
        bar("Erreur de chargement des achats: ${response.statusCode}");
      }
    } catch (e) {
      print(e);
      bar("Erreur de connexion lors de la récupération des achats: ${e.toString()}");
    }
  }

  Future<void> getrecords() async {
    var url = "$Adress_IP/FOURNISSEUR/getfournisseur.php";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          d = jsonDecode(response.body);
        });
      } else {
        bar("Erreur de chargement des fournisseurs: ${response.statusCode}");
      }
    } catch (e) {
      print(e);
      bar("Erreur de connexion lors de la récupération des fournisseurs: ${e.toString()}");
    }
  }

  Future<void> updatedatas(String va, String v) async {
    setState(() {
      _isLoading = true; // Show loader
    });
    try {
      var url = "$Adress_IP/APPROVISIONNEMNT/updateapprovisionnement.php";
      Uri ulr = Uri.parse(url);
      var request = http.MultipartRequest('POST', ulr);
      request.fields['id_approvionnement'] = va;
      request.fields['fournisseur_id'] =
          v; // Use the passed value 'v' for supplier_id
      var res = await request.send();
      var response = await http.Response.fromStream(res);

      if (response.statusCode == 200) {
        bar("Modification réussie");
        await getrecord(); // Refresh data after update
      } else {
        bar("Erreur de modification: ${response.statusCode}");
      }
    } catch (e) {
      bar(e.toString());
      print(e);
    } finally {
      setState(() {
        _isLoading = false; // Hide loader
      });
      if (mounted) Navigator.pop(context); // Close dialog if still mounted
    }
  }

  Future<void> savadatas() async {
    setState(() {
      _isLoading = true; // Show loader
    });
    try {
      var url = "$Adress_IP/APPROVISIONNEMNT/insertapprovisionnement.php";
      Uri ulr = Uri.parse(url);
      var request = http.MultipartRequest('POST', ulr);
      request.fields['fournisseur_id'] = selectedname;
      var res = await request.send();
      var response = await http.Response.fromStream(res);

      if (response.statusCode == 200) {
        bar("Ajout réussi");
        await getrecord(); // Refresh data after save
      } else {
        bar("Erreur d'ajout: ${response.statusCode}");
      }
    } catch (e) {
      bar(e.toString());
      print(e);
    } finally {
      setState(() {
        _isLoading = false; // Hide loader
      });
      if (mounted) Navigator.pop(context); // Close dialog if still mounted
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

  Future<void> _selected(TextEditingController dateController) async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));

    if (picked != null) {
      setState(() {
        dateController.text = picked.toString().split(" ")[0];
      });
    } else {
      // If the user cancels, keep the current date or set a default.
      // For this example, we'll keep the current date if nothing selected.
      dateController.text = DateTime.now().toString().split(" ")[0];
    }
  }

  Widget buildEditDialog(int index) {
    if (data[index]["fournisseur_id"] != null) {
      selectedvalue = data[index]["fournisseur_id"];
      selectedname = data[index]["fournisseur_id"].toString();
    } else {
      selectedvalue = null;
      selectedname = null;
    }
    dateone.text = data[index]["date_approvisionnement"] ?? "";

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
              "Modifier un achat",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            DropdownButtonFormField<String>(
              value: selectedvalue,
              items: d.map((list) {
                return DropdownMenuItem<String>(
                  value: list["id_fournisseur"].toString(),
                  child: Text(list["noms"]),
                );
              }).toList(),
              icon: const Icon(Icons.arrow_drop_down_circle),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.production_quantity_limits),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                hintText: "Fournisseur",
                labelText: "Fournisseur",
              ),
              onChanged: (String? newValue) {
                setState(() {
                  selectedvalue = newValue;
                  selectedname = newValue;
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
              label:
                  const Text("Modifier", style: TextStyle(color: Colors.black)),
              onPressed: () {
                if (selectedname != null) {
                  updatedatas(data[index]["id_approvisionnement"].toString(),
                      selectedname!);
                } else {
                  bar("Veuillez sélectionner un fournisseur.");
                }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty &&
                  status ==
                      'Success' // Check if data is empty after successful fetch
              ? const Center(
                  child: Text(
                    "Aucun achat disponible.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
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
                                  builder: (context) => Listdetail(data[index]
                                          ["id_approvisionnement"]
                                      .toString()),
                                ),
                              );
                            },
                            title: Text(
                              data[index]["fournisseur"] ??
                                  "N/A", // Handle potential null
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
                                    builder: (context) =>
                                        buildEditDialog(index),
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
                                                    ["id_approvisionnement"])
                                                .then((_) {
                                              // After deletion, refresh the list
                                              Navigator.pop(
                                                  context); // Close the dialog
                                            });
                                          },
                                          child: const Text("Confirmer"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                                context); // Close the dialog
                                          },
                                          child: const Text("Annuler"),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w400),
                            ),
                            subtitle: Text(data[index]
                                    ["date_approvisionnement"] ??
                                "N/A"), // Handle potential null
                          ),
                        ),
                      ),
                    );
                  }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Reset selected values for new entry
          setState(() {
            selectedvalue = null;
            selectedname = null;
          });
          dateone.clear(); // Clear date field for new entry

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
                          DropdownButtonFormField<String>(
                            items: d.map((list) {
                              return DropdownMenuItem<String>(
                                value: list["id_fournisseur"].toString(),
                                child: Text(list["noms"]),
                              );
                            }).toList(),
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
                              labelText: "Fournisseur",
                            ),
                            onChanged: (String? value) {
                              setState(() {
                                selectedvalue = value;
                                selectedname = value;
                              });
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
                                ),
                                focusColor: Colors.green,
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
                              "Enregistrer",
                              style: TextStyle(color: Colors.black),
                            ),
                            onPressed: () {
                              if (selectedname != null) {
                                savadatas();
                              } else {
                                bar("Veuillez sélectionner un fournisseur.");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 227, 174, 131),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        ],
                      ),
                    ));
              });
        },
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}
