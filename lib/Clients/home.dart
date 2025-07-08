import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../ip.dart';
import 'Addclient.dart';
import 'package:http/http.dart' as http;

class HomeClient extends StatefulWidget {
  const HomeClient({super.key});

  @override
  State<HomeClient> createState() => _HomeClientState();
}

class _HomeClientState extends State<HomeClient> {
  TextEditingController nom = TextEditingController();
  TextEditingController adresse = TextEditingController();
  TextEditingController mail = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController code = TextEditingController();

  double screenheigth = 0;
  double screenwith = 0;

  List data = [];
  String status = '';
  bool _isLoading = false; // Renamed for clarity and consistency
  String _statusMessage = ''; // To display messages like "No clients available"

  @override
  void initState() {
    super.initState();
    _loadClients(); // Call a method to load initial data
  }

  // A helper method to load initial client data
  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true; // Show loader
      _statusMessage = ''; // Clear any previous status message
    });
    try {
      await getrecord(); // Fetch client records
      if (data.isEmpty) {
        _statusMessage = "Aucun client disponible.";
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

  Future<void> delrecord(String id) async {
    setState(() {
      _isLoading = true; // Show loader during deletion
    });
    try {
      var url = "$Adress_IP/CLIENT/deleteclient.php";
      var result =
          await http.post(Uri.parse(url), body: {"id_client": id.toString()});
      var reponse = jsonDecode(result.body);

      if (reponse["Success"] == "True") {
        print("Record deleted successfully");
        _showSnackBar("Client supprimé avec succès.");
        await getrecord(); // Refresh data after deletion
      } else {
        print(
            "Error during deletion: ${reponse["message"]}"); // Assuming "message" key for errors
        _showSnackBar(
            "Échec de la suppression: ${reponse["message"] ?? 'Erreur inconnue'}");
      }
    } catch (e) {
      print("Error deleting record: $e");
      _showSnackBar(
          "Erreur de connexion lors de la suppression: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false; // Hide loader
      });
    }
  }

  Future<void> getrecord() async {
    // This method is called by _loadClients and by other actions,
    // so it doesn't manage _isLoading state directly here.
    // _loadClients or the calling function will handle it.
    try {
      var url = "$Adress_IP/CLIENT/getclient.php";
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
        });
      } else {
        _showSnackBar(
            "Erreur de chargement des clients: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching records: $e");
      _showSnackBar(
          "Erreur de connexion lors de la récupération des clients: ${e.toString()}");
    }
  }

// EDIT client
  Future<void> update() async {
    setState(() {
      _isLoading = true; // Show loader during update
    });
    try {
      var url = "$Adress_IP/CLIENT/updateclient.php";
      var res = await http.post(Uri.parse(url), body: {
        "noms": nom.text,
        "adresse": adresse.text,
        "mail": mail.text,
        "telephone": phone.text,
        "id": code.text
      });

      var repoe = jsonDecode(res.body);
      print('Update response: $repoe');

      if (repoe["message"] == "Mise à jour réussie.") {
        print("Record updated successfully");
        _showSnackBar("Client mis à jour avec succès.");
        await getrecord(); // Refresh data after update
      } else if (repoe["error"] == "Paramètres manquants.") {
        print("Missing parameters error");
        _showSnackBar("Erreur: Paramètres manquants pour la mise à jour.");
      } else {
        print("Error on update: ${repoe["message"]}");
        _showSnackBar(
            "Échec de la mise à jour: ${repoe["message"] ?? 'Erreur inconnue'}");
      }
    } catch (e) {
      print("Error updating record: $e");
      _showSnackBar(
          "Erreur de connexion lors de la mise à jour: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false; // Hide loader
      });
      if (mounted)
        Navigator.pop(context); // Close the bottom sheet if still mounted
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadClients, // Use _loadClients for refresh
        child: _isLoading // Afficher le loader si _isLoading est vrai
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _statusMessage
                    .isNotEmpty // Show status message if data is empty or error
                ? Center(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.all(5),
                        child: ListTile(
                          onTap: () {
                            // You can activate navigation here if needed
                          },
                          title: Text(data[index]["noms"] ??
                              "N/A"), // Handle potential null
                          subtitle: Text(data[index]["telephone"] ??
                              "N/A"), // Handle potential null
                          leading: Hero(
                            tag: data[index]["id_client"],
                            child: const CircleAvatar(
                              radius: 30,
                              child: Icon(Icons.person_2_outlined),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bouton Modifier
                              IconButton(
                                icon: const Icon(Icons.edit_note_outlined,
                                    color: Colors.blue),
                                onPressed: () {
                                  setState(() {
                                    nom.text = data[index]["noms"] ?? '';
                                    adresse.text = data[index]["adresse"] ?? '';
                                    mail.text = data[index]["mail"] ?? '';
                                    phone.text = data[index]["telephone"] ?? '';
                                    code.text = data[index]["id_client"]
                                        .toString(); // Corrected to id_client
                                  });

                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled:
                                        true, // Allow content to be scrollable if keyboard appears
                                    builder: (context) => Padding(
                                      // Added padding
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(context)
                                            .viewInsets
                                            .bottom,
                                        left: 25,
                                        right: 25,
                                      ),
                                      child: ListView(
                                        shrinkWrap:
                                            true, // Make ListView take only necessary space
                                        children: [
                                          const SizedBox(height: 20),
                                          const Text(
                                            "Modifier Client",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: nom,
                                            decoration: const InputDecoration(
                                              prefixIcon:
                                                  Icon(Icons.person_2_outlined),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10)),
                                                borderSide: BorderSide(
                                                    color: Colors.orange),
                                              ),
                                              hintText: "Nom du client",
                                              labelText: "Nom",
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: adresse,
                                            decoration: const InputDecoration(
                                              prefixIcon:
                                                  Icon(Icons.place_outlined),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10)),
                                                borderSide: BorderSide(
                                                    color: Colors.orange),
                                              ),
                                              hintText: "Adresse du client",
                                              labelText: "Adresse",
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: phone,
                                            keyboardType: TextInputType.phone,
                                            decoration: const InputDecoration(
                                              prefixIcon: Icon(Icons.phone),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10)),
                                                borderSide: BorderSide(
                                                    color: Colors.orange),
                                              ),
                                              hintText: "Contact du client",
                                              labelText: "Contact",
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: mail,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                              prefixIcon:
                                                  Icon(Icons.email_outlined),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10)),
                                                borderSide: BorderSide(
                                                    color: Colors.orange),
                                              ),
                                              hintText: "Mail du client",
                                              labelText: "Mail",
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton.icon(
                                            icon: const Icon(
                                                Icons.save_alt_outlined,
                                                color: Colors.black),
                                            label: const Text("Confirmer",
                                                style: TextStyle(
                                                    color: Colors.black)),
                                            onPressed: () {
                                              update();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              elevation: 0,
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 240, 184, 138),
                                              fixedSize: const Size(300, 45),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                              height:
                                                  20), // Add some space at the bottom
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // // Bouton Supprimer
                              // IconButton(
                              //   icon:
                              //       const Icon(Icons.delete, color: Colors.red),
                              //   onPressed: () {
                              //     showDialog(
                              //       context: context,
                              //       builder: (context) => CupertinoAlertDialog(
                              //         title: const Text(
                              //             "Voulez-vous vraiment supprimer ?"),
                              //         actions: [
                              //           Row(
                              //             mainAxisAlignment:
                              //                 MainAxisAlignment.center,
                              //             children: [
                              //               TextButton(
                              //                 onPressed: () {
                              //                   delrecord(data[index]
                              //                               ["id_client"]
                              //                           .toString()) // Corrected to id_client
                              //                       .then((_) {
                              //                     Navigator.pop(
                              //                         context); // Close dialog after action
                              //                   });
                              //                 },
                              //                 child: const Text("Effectuer"),
                              //               ),
                              //               TextButton(
                              //                 onPressed: () {
                              //                   Navigator.pop(
                              //                       context); // Close dialog
                              //                 },
                              //                 child: const Text("Annuler"),
                              //               ),
                              //             ],
                              //           ),
                              //         ],
                              //       ),
                              //     );
                              //   },
                              // ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AddClient()))
              .then((_) =>
                  _loadClients()); // Refresh data when returning from AddClient
        },
        disabledElevation: 10,
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ), // Changed color to black for better visibility
        backgroundColor: Theme.of(context)
            .floatingActionButtonTheme
            .backgroundColor, // Use default background
      ),
    );
  }
}
