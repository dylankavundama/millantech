import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/ip.dart'; // Assuming Adress_IP is defined here

class Cat extends StatefulWidget {
  const Cat({super.key});

  @override
  State<Cat> createState() => _CatState();
}

class _CatState extends State<Cat> {
  double screenheigth = 0;
  double screenwith = 0;

  List data = [];
  String status = '';
  bool _isLoading = false; // New state variable for loading

  @override
  void initState() {
    super.initState();
    getrecord();
  }

  Future<void> delrecord(var id) async {
    try {
      setState(() {
        _isLoading = true; // Show loader when deleting
      });
      String tmp = id.toString();
      var url = "$Adress_IP/CATEGORIEPROD/deletecategorie.php";
      var result = await http.post(Uri.parse(url), body: {"id": tmp});
      var reponse = jsonDecode(result.body);
      if (reponse["Success"] == "succes") {
        print("record deleted");
        debugPrint("");
        await getrecord(); // Await getrecord to ensure data is refreshed after deletion
      } else {
        print("Erreur de suppression");
        await getrecord(); // Await getrecord even on error to refresh
      }
    } catch (e) {
      print(e);
      bar("Erreur: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false; // Hide loader after deletion attempt
      });
    }
  }

  Future<void> getrecord() async {
    setState(() {
      _isLoading = true; // Show loader when fetching data
    });
    var url = "$Adress_IP/CATEGORIEPROD/getcategorie.php";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
          print(data);
          status = 'Success';
        });
      } else {
        bar("Erreur de chargement des données: ${response.statusCode}");
      }
    } catch (e) {
      print(e);
      bar("Erreur de connexion: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false; // Hide loader after data fetch attempt
      });
    }
  }

  Future<void> savadatas() async {
    try {
      setState(() {
        _isLoading = true; // Show loader when saving data
      });
      var url = "$Adress_IP/CATEGORIEPROD/insertcategorie.php";
      Uri ulr = Uri.parse(url);
      var request = http.MultipartRequest('POST', ulr);
      request.fields['designation'] = designation.text;
      var res = await request.send();
      var response = await http.Response.fromStream(res);

      if (response.statusCode == 200) {
        bar("Success insert");
        await getrecord(); // Await getrecord to ensure data is refreshed
      } else {
        bar("Error insert: ${response.statusCode}");
      }
    } catch (e) {
      bar(e.toString());
      print(e);
    } finally {
      setState(() {
        _isLoading = false; // Hide loader after saving data
      });
      Navigator.pop(
          context); // This should probably be outside the finally block if it depends on success
    }
  }

  Future<void> update() async {
    try {
      setState(() {
        _isLoading = true; // Show loader when updating data
      });
      var url = "$Adress_IP/CATEGORIEPROD/updatecategorie.php";
      Uri ulr = Uri.parse(url);
      var request = http.MultipartRequest('POST', ulr);
      request.fields['designation'] = designation.text;
      request.fields['id_categorie'] = id.text;
      var res = await request.send();
      var response = await http.Response.fromStream(res);
      if (response.statusCode == 200) {
        bar("Success update");
        await getrecord(); // Await getrecord to ensure data is refreshed
      } else {
        bar("Error update: ${response.statusCode}");
      }
    } catch (e) {
      bar(e.toString());
      print(e);
    } finally {
      setState(() {
        _isLoading = false; // Hide loader after updating data
      });
      Navigator.pop(
          context); // This should probably be outside the finally block if it depends on success
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

  TextEditingController designation = TextEditingController();
  TextEditingController id = TextEditingController();

  @override
  Widget build(BuildContext context) {
    screenwith = MediaQuery.of(context).size.width;
    screenheigth = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(), // Show loader when loading
            )
          : data.isEmpty && status == 'Success'
              ? const Center(
                  child: Text(
                    "Aucune catégorie disponible.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        onTap: () {
                          designation.text = data[index]["designation"];
                          id.text = data[index]["id_categorie"].toString();

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20.0),
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: ListView(
                                    children: [
                                      const Text(
                                        "Modifier la catégorie",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(height: 15),
                                      TextField(
                                        controller: designation,
                                        decoration: const InputDecoration(
                                            prefixIcon: Icon(Icons.description),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.orange),
                                            ),
                                            hintText: "Designation Categorie",
                                            labelText: "Designation"),
                                      ),
                                      const SizedBox(height: 25),
                                      ElevatedButton.icon(
                                        icon: const Icon(
                                          Icons.save_alt_outlined,
                                          color: Colors.black,
                                        ),
                                        label: const Text(
                                          "Enregistrer les modifications",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        onPressed: () {
                                          update();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 227, 174, 131),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        leading: const Icon(
                          Icons.category,
                        ),
                        title: Text(
                          "Catégorie: ${data[index]["designation"]}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                            onPressed: () {
                              delrecord(data[index]["id_categorie"]);
                            },
                            icon: const Icon(
                              Icons.delete,
                            )),
                      ),
                    );
                  }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          designation.clear(); // Clear the text field for new entry
          id.clear(); // Clear the id field as it's for new entry
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListView(
                    children: [
                      const Text(
                        "Ajouter une catégorie",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: designation,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                            hintText: "Désignation Catégorie",
                            labelText: "Désignation"),
                      ),
                      const SizedBox(height: 25),
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
                          savadatas();
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
          Icons.add_outlined,
        ),
      ),
    );
  }
}
