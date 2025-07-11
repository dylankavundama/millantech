import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/ip.dart';

class AddClient extends StatefulWidget {
  const AddClient({super.key});

  @override
  State<AddClient> createState() => _AddClientState();
}

class _AddClientState extends State<AddClient> {
  TextEditingController nom = TextEditingController();
  TextEditingController adresse = TextEditingController();
  TextEditingController mail = TextEditingController();
  TextEditingController phone = TextEditingController();
  late String adresseip;
  Future<void> savadatas() async {
    var url = "$Adress_IP/CLIENT/insertclient.php";
    Uri ulr = Uri.parse(url);

    await http.post(ulr, body: {
      "noms": nom.text,
      "adresse": adresse.text,
      "mail": mail.text,
      "telephone": phone.text
    });

    // ignore: use_build_context_synchronously
    Navigator.pop(
      context,
    );
  }

  @override
  void initState() {
    // adresseip = currentip();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'Nouveau Client',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.bold,
        ),
      )),
      body: ListView.builder(
          itemCount: 1, // Number of items in the list
          itemBuilder: (context, index) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 30, right: 30),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      TextField(
                          controller: nom,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_2_outlined),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.orange),
                              ),
                              hintText: "Nom du client",
                              labelText: "Nom")),
                      const SizedBox(height: 25),
                      TextField(
                          controller: adresse,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.place_outlined),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.orange),
                              ),
                              hintText: "Adresse du client",
                              labelText: "Adresse")),
                      const SizedBox(height: 25),
                      TextField(
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.orange),
                              ),
                              hintText: "Contact du client",
                              labelText: "Contact")),
                      const SizedBox(height: 25),
                      TextField(
                          controller: mail,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.orange),
                              ),
                              // border: OutlineInputBorder(

                              // ),
                              hintText: "Mail du client",
                              labelText: "mail")),
                      const SizedBox(
                        height: 10,
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
                          savadatas();
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor:
                              const Color.fromARGB(255, 240, 184, 138),
                          fixedSize: const Size(300, 45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }
}
