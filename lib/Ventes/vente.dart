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
  List data = [];
  var selectedvalue;
  var selectedname;
  List d = []; // For clients data
  bool _isLoading = false; // New state variable for loading
  String _statusMessage = ''; // To display messages like "No sales available"

  @override
  void initState() {
    super.initState();
    _loadData(); // Call a method to load all initial data
  }

  // A helper method to load all necessary data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // Show loader
      _statusMessage = ''; // Clear previous messages
    });
    try {
      await Future.wait([
        getrecord(), // Fetch sales records
        getrecords(), // Fetch client records
      ]);
      if (data.isEmpty) {
        _statusMessage = "Aucune vente disponible.";
      }
    } catch (e) {
      _statusMessage = "Erreur de chargement des données: ${e.toString()}";
      print(e); // Log the error for debugging
    } finally {
      setState(() {
        _isLoading = false; // Hide loader
      });
    }
  }

  Future<void> getrecords() async {
    var url = "$Adress_IP/CLIENT/getclient.php";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          d = jsonDecode(response.body);
        });
      } else {
        bar("Erreur de chargement des clients: ${response.statusCode}");
      }
    } catch (e) {
      print(e);
      bar("Erreur de connexion lors de la récupération des clients: ${e.toString()}");
    }
  }

  Future<void> getrecord() async {
    var url = "$Adress_IP/VENTE/getvente.php";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
        });
      } else {
        bar("Erreur de chargement des ventes: ${response.statusCode}");
      }
    } catch (e) {
      print(e);
      bar("Erreur de connexion lors de la récupération des ventes: ${e.toString()}");
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

  Future<void> delrecord(var id) async {
    setState(() {
      _isLoading = true; // Show loader
    });
    try {
      var url = "$Adress_IP/VENTE/deletevente.php";
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

  Future<void> savadatas() async {
    setState(() {
      _isLoading = true; // Show loader
    });
    try {
      var url = "$Adress_IP/VENTE/insertvente.php";
      Uri ulr = Uri.parse(url);
      var request = http.MultipartRequest('POST', ulr);
      request.fields['client_id'] = selectedname;
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

  double screenheigth = 0;
  double screenwith = 0;

  @override
  Widget build(BuildContext context) {
    screenwith = MediaQuery.of(context).size.width;
    screenheigth = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => report()));
            },
            icon: const Icon(Icons.file_download_done_outlined),
          )
        ],
        title: const AppTitle(),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loader when loading
          : _statusMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                                  builder: (context) => Lisventedet(
                                      data[index]["id_vente"].toString()),
                                ),
                              );
                            },
                            title: Text(
                              data[index]["client"] ??
                                  "N/A", // Handle potential null
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            leading: Text(
                              "${index + 1}. ",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w400),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.insert_drive_file_sharp,
                                      color: Color.fromARGB(255, 11, 92, 23)),
                                  onPressed: () {
                                    // Action de modification ou affichage modal - not implemented yet
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          CupertinoAlertDialog(
                                        title: const Text(
                                            "Voulez-vous vraiment supprimer ?"),
                                        actions: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  delrecord(data[index]
                                                              ["id_vente"]
                                                          .toString())
                                                      .then((_) {
                                                    // After deletion, refresh the list and close dialog
                                                    Navigator.pop(context);
                                                  });
                                                },
                                                child: const Text("Effectuer"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(
                                                      context); // Close dialog
                                                },
                                                child: const Text("Annuler"),
                                              ),
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
          // Reset selected values for new entry
          setState(() {
            selectedvalue = null;
            selectedname = null;
          });

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
                        "Faire une Vente",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      DropdownButtonFormField<String>(
                        items: d.map((list) {
                          return DropdownMenuItem<String>(
                            value: list["id_client"].toString(),
                            child: Text(list["noms"]),
                          );
                        }).toList(),
                        value: selectedvalue,
                        icon: const Icon(Icons.arrow_drop_down_circle),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons
                              .person), // Changed to person icon for client
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                          hintText: "Client",
                          labelText: "Client",
                        ),
                        onChanged: (String? value) {
                          setState(() {
                            selectedvalue = value;
                            selectedname = value;
                          });
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
                          "Enregistrer",
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () {
                          if (selectedname != null) {
                            savadatas();
                          } else {
                            bar("Veuillez sélectionner un client.");
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
                ),
              );
            },
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}
