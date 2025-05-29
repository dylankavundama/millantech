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
  // String adress = currentip();

  TextEditingController nom = TextEditingController();
  TextEditingController adresse = TextEditingController();
  TextEditingController mail = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController code = TextEditingController();

  double screenheigth = 0;

  double screenwith = 0;

  List data = [];
  String status = '';
  Future<void> delrecord(String id) async {
    try {
      var url = "$Adress_IP/CLIENT/deleteclient.php";

      var result =
          await http.post(Uri.parse(url), body: {"id_client": id.toString()});
      var reponse = jsonDecode(result.body);
      if (reponse["Success"] == "True") {
        print("record deleted");
        debugPrint("");
        getrecord();
      } else {
        print("Erreur de suppression");
        getrecord();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> getrecord() async {
    var url = "$Adress_IP/CLIENT/getclient.php";

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

// EDIT client
  Future<void> update() async {
    try {
      var url = "$Adress_IP/CLIENT/updateclient.php";
      //print("onclick");
      var res = await http.post(Uri.parse(url), body: {
        "noms": nom.text,
        "adresse": adresse.text,
        "mail": mail.text,
        "telephone": phone.text,
        "id": code.text
      });

      var repoe = jsonDecode(res.body);
      print('object');
      getrecord();
      if (repoe["message"] == "Mise à jour réussie.") {
        print("record updated");

        getrecord();
      } else if (repoe["error"] == "Paramètres manquants.") {
        print("error");
        getrecord();
      } else {
        print("Error on update");
        getrecord();
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getrecord();
    _refreshData();
    super.initState();
  }

  Future<void> _refreshData() async {
    await getrecord();
  }

  bool isLoading = false; // Ajout de la variable de chargement
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: isLoading // Afficher le loader si isLoading est vrai
            ? const Center(
                child: CircularProgressIndicator(),
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
                        // Tu peux activer la navigation ici si besoin

                        // Navigator.push(context, MaterialPageRoute(builder: (context)=>HeroDetails(items: controller.items[index])));
                      },
                      title: Text(data[index]["noms"]),
                      subtitle: Text(data[index]["telephone"]),
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
                                nom.text = data[index]["noms"];

                                adresse.text = data[index]["adresse"];

                                mail.text = data[index]["mail"];

                                phone.text = data[index]["telephone"];

                                code.text =
                                    data[index]["id_fournisseur"].toString();
                              });

                              showModalBottomSheet(
                                context: context,
                                builder: (context) => ListView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 25),
                                  children: [
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: nom,
                                      decoration: const InputDecoration(
                                        prefixIcon:
                                            Icon(Icons.person_2_outlined),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                          borderSide:
                                              BorderSide(color: Colors.orange),
                                        ),
                                        hintText: "Nom du client",
                                        labelText: "Nom",
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: adresse,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.place_outlined),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                          borderSide:
                                              BorderSide(color: Colors.orange),
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
                                          borderSide:
                                              BorderSide(color: Colors.orange),
                                        ),
                                        hintText: "Contact du client",
                                        labelText: "Contact",
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: mail,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.email_outlined),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                          borderSide:
                                              BorderSide(color: Colors.orange),
                                        ),
                                        hintText: "Mail du client",
                                        labelText: "Mail",
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.save_alt_outlined,
                                          color: Colors.black),
                                      label: const Text("Confirmer",
                                          style:
                                              TextStyle(color: Colors.black)),
                                      onPressed: () {
                                        update();

                                        getrecord();

                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: const Color.fromARGB(
                                            255, 240, 184, 138),
                                        fixedSize: const Size(300, 45),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Bouton Supprimer

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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            print(data[index]
                                                ["id_approvisionnement"]);

                                            delrecord(data[index]["id_client"]
                                                .toString());

                                            setState(() {
                                              Navigator.pop(context);
                                            });
                                          },
                                          child: const Text("Effectuer"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
              MaterialPageRoute(builder: (context) => const AddClient()));
        },
        disabledElevation: 10,
        child: const Icon(Icons.add),
      ),
    );
  }
}
