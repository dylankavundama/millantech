import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../ip.dart';
import 'AddFournisseur.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class Homefourn extends StatefulWidget {
  const Homefourn({super.key});
  @override
  State<Homefourn> createState() => _HomefournState();
}

class _HomefournState extends State<Homefourn> {
  // String adress = currentip();
  double screenheigth = 0;
  double screenwith = 0;
  List data = [];
  String status = '';
  Future<void> update() async {
  setState(() {
    isLoading = true;
  });
  try {
    var url = "$Adress_IP/FOURNISSEUR/updatefournisseur.php";
    var res = await http.post(Uri.parse(url), body: {
      "noms": nom.text,
      "adresse": adresse.text,
      "mail": mail.text,
      "telephone": phone.text,
      "id_fournisseur": code.text
    });
    var repoe = jsonDecode(res.body);
    if (repoe["message"] == "Mise à jour réussie.") {
      bar("Mise à jour réussie.");
    } else if (repoe["error"] == "Paramètres manquants.") {
      bar("Paramètres manquants.");
    } else {
      bar("Erreur lors de la mise à jour.");
    }
    await getrecord();
  } catch (e) {
    print(e);
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  Future<void> delrecord(String id) async {
    try {
      var url = "$Adress_IP/FOURNISSEUR/deletefournisseur.php";
      try {
        var result = await http
            .post(Uri.parse(url), body: {"id_fournisseur": id.toString()});
        var reponse = jsonDecode(result.body);
        if (result.statusCode == 200) {
          reponse["Success"] = "True";
          bar("supprimer");
          getrecord();
        } else {
          bar("Error de suppression");
          getrecord();
        }
      } catch (e) {
        bar(e.toString());
      }
    } catch (e) {
      print(e);
    }
  }

Future<void> getrecord() async {
  setState(() {
    isLoading = true;
  });
  try {
    var url = "$Adress_IP/FOURNISSEUR/getfournisseur.php";
    var response = await http.get(Uri.parse(url));
    setState(() {
      data = jsonDecode(response.body);
    });
  } catch (e) {
    print(e);
  } finally {
    setState(() {
      isLoading = false;
    });
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

  TextEditingController nom = TextEditingController();
  TextEditingController adresse = TextEditingController();
  TextEditingController mail = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController code = TextEditingController();
  @override
  void initState() {
    super.initState();
    getrecord();
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
        child: isLoading
    ? const Center(child: CircularProgressIndicator(color: Colors.red,))
    : ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    margin: const EdgeInsets.all(5),
                    child: ListTile(
                      onTap: () {
                        // Navigation désactivée (activable si besoin)
                        // Navigator.push(context, MaterialPageRoute(builder: (context)=>HeroDetailsFournisseur(items: controller.items[index])));
                      },
                      title: Text(data[index]["noms"]),
                      subtitle: Text(data[index]["telephone"]),
                      leading: Hero(
                        tag: data[index]["id_fournisseur"],
                        child: const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person_3_outlined),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                  padding: const EdgeInsets.only(
                                      right: 25, left: 25),
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
                                        hintText: "Contact",
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
                                        hintText: "Mail du Fournisseur",
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
                                        setState(() {
                                          getrecord();
                                        });
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
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IconButton(
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
                                              delrecord(data[index]
                                                      ["id_fournisseur"]
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
              MaterialPageRoute(builder: (context) => const AddFournisseur()));
        },
        disabledElevation: 10,
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}
