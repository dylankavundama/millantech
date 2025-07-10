import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/Ventes/Detailsventes/AddVentedetail.dart';
import 'package:stocktrue/Ventes/ListdetVente.dart';
import '../ip.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Import dropdown_search

class Ventes extends StatefulWidget {
  const Ventes({super.key});

  @override
  State<Ventes> createState() => _VentesState();
}

class _VentesState extends State<Ventes> {
  List ventes = [];
  List clients = [];
  String? clientSelectionne;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    setState(() => isLoading = true);
    await Future.wait([
      chargerVentes(),
      chargerClients(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> chargerVentes() async {
    try {
      final url = Uri.parse("$Adress_IP/VENTE/getvente.php");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List fetchedVentes = List.from(jsonDecode(response.body));
        // Sort the sales by 'date_vente' in descending order
        fetchedVentes.sort((a, b) {
          // Assuming 'date_vente' is a string in a format that can be parsed by DateTime
          // If 'date_vente' might be null or missing, add null checks
          final dateA = DateTime.tryParse(a["date_vente"] ?? '');
          final dateB = DateTime.tryParse(b["date_vente"] ?? '');

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1; // Put null dates at the end
          if (dateB == null) return -1; // Put null dates at the end

          return dateB.compareTo(dateA); // Descending order
        });
        setState(() => ventes = fetchedVentes);
      }
    } catch (_) {
      // Consider logging the error here.
    }
  }

  Future<void> chargerClients() async {
    try {
      final url = Uri.parse("$Adress_IP/CLIENT/getclient.php");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() => clients = List.from(jsonDecode(response.body)));
      }
    } catch (_) {
      // Consider logging the error here.
    }
  }

  Future<void> supprimerVente(String idVente) async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("$Adress_IP/VENTE/deletevente.php");
      await http.post(url, body: {"id": idVente});
      await chargerVentes();
    } catch (_) {
      // Consider logging the error here.
    }
    setState(() => isLoading = false);
  }

  Future<void> ajouterClient(BuildContext context,
      {BuildContext? venteDialogContext}) async {
    final nomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    String? idNouveauClient;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouveau client"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(labelText: "Nom"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: telCtrl,
              decoration: const InputDecoration(labelText: "Téléphone"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.trim().isEmpty || telCtrl.text.trim().isEmpty) {
                // Show a snackbar or toast for validation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez remplir tous les champs.')),
                );
                return;
              }
              final url = Uri.parse("$Adress_IP/CLIENT/insertclient.php");
              final response = await http.post(url, body: {
                "noms": nomCtrl.text.trim(),
                "telephone": telCtrl.text.trim(),
                "adresse": "",
                "mail": ""
              });
              if (response.statusCode == 200) {
                await chargerClients();
                final nouveau = clients.firstWhere(
                  (c) =>
                      c["noms"] == nomCtrl.text.trim() &&
                      c["telephone"] == telCtrl.text.trim(),
                  orElse: () =>
                      null, // Use null as orElse return for List.firstWhere
                );
                if (nouveau != null) {
                  idNouveauClient = nouveau["id_client"].toString();
                  // Créer automatiquement une vente pour ce client
                  final urlVente =
                      Uri.parse("$Adress_IP/VENTE/insertvente.php");
                  final req = http.MultipartRequest('POST', urlVente);
                  req.fields['client_id'] = idNouveauClient!;
                  final res = await req.send();
                  if (res.statusCode == 200) {
                    await chargerVentes();
                  } else {
                    // Handle error if automatic sale creation fails
                    print('Failed to create automatic sale: ${res.statusCode}');
                  }
                } else {
                  print(
                      'Newly added client not found in updated clients list.');
                }
              } else {
                // Handle client insertion error
                print('Failed to add client: ${response.statusCode}');
              }
              // Make sure to pop the current dialog (add client)
              if (mounted) Navigator.pop(ctx);
              if (venteDialogContext != null) {
                // And then pop the sales creation dialog if it exists
                if (Navigator.canPop(venteDialogContext)) {
                  Navigator.pop(venteDialogContext);
                }
              }
              // Refresh the Ventes page after popping
              await chargerDonnees();
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
    if (idNouveauClient != null) {
      setState(() => clientSelectionne = idNouveauClient);
    }
  }

  Future<bool> verifierStockGlobal() async {
    try {
      final url = Uri.parse("$Adress_IP/PRODUIT/getproduit.php");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final produits = List.from(jsonDecode(response.body));
        print('DEBUG STOCK PRODUITS:');
        for (var p in produits) {
          print(
              'Produit: ${p["designation"] ?? p["id_produit"]} - Stock: ${p["quantite"]}');
        }
        return produits.any((p) =>
            int.tryParse(p["quantite"].toString()) != null &&
            int.parse(p["quantite"].toString()) > 0);
      }
    } catch (e) {
      print('Erreur lors de la vérification du stock: $e');
    }
    return false;
  }

  Future<void> ajouterVente(BuildContext context) async {
    // Reset client selection before showing dialog
    clientSelectionne = null;

    await showDialog(
      context: context,
      builder: (ctx) {
        // Use a local state variable for the dialog's dropdown
        String? dialogClientSelectionne = clientSelectionne;

        return StatefulBuilder(
          // Use StatefulBuilder to manage dialog's internal state
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Nouvelle vente"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownSearch<Map<String, dynamic>>(
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      // Optional: Add a custom search field hint
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Rechercher un client...",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.fromLTRB(12, 12, 8, 0),
                        ),
                      ),
                      // Optional: Customizing how items are displayed in the popup
                      itemBuilder: (context, client, isSelected) {
                        return ListTile(
                          title: Text(client["noms"] ?? "Client inconnu"),
                          subtitle: Text(client["telephone"] ?? ""),
                        );
                      },
                    ),
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Client",
                        hintText: "Sélectionner un client",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.fromLTRB(12, 12, 8, 0),
                      ),
                    ),
                    items: clients.cast<
                        Map<String, dynamic>>(), // Cast to the expected type
                    itemAsString: (Map<String, dynamic> client) =>
                        client["noms"] ?? "Client inconnu",
                    selectedItem: clients.firstWhere(
                      (c) =>
                          c["id_client"].toString() == dialogClientSelectionne,
                      orElse: () => null, // Use null for orElse
                    ) as Map<String, dynamic>?, // Cast to the expected type
                    onChanged: (Map<String, dynamic>? selectedClient) {
                      setDialogState(() {
                        dialogClientSelectionne =
                            selectedClient?["id_client"].toString();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add, color: Colors.orange),
                    label: const Text("Ajouter un client"),
                    onPressed: () async {
                      // Pass ctx as the venteDialogContext
                      await ajouterClient(context, venteDialogContext: ctx);
                      // After adding a client and dialogs are popped, this clientSelectionne will be updated
                      // This state will then be used when adding the sale
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dialogClientSelectionne == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Veuillez sélectionner un client.')),
                      );
                      return;
                    }
                    // Vérifier le stock global avant d'enregistrer la vente
                    final stockOk = await verifierStockGlobal();
                    if (!stockOk) {
                      // ignore: use_build_context_synchronously
                      if (!mounted) return; // Check if widget is still mounted
                      await showDialog(
                        context: context,
                        builder: (dctx) => AlertDialog(
                          title: const Text("Stock insuffisant"),
                          content: const Text(
                              "Aucun produit n'est en stock. Impossible de créer une vente."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dctx),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                      if (!mounted) return; // Check if widget is still mounted
                      Navigator.pop(
                          ctx); // Ferme le dialogue de création de vente
                      return;
                    }
                    final url = Uri.parse("$Adress_IP/VENTE/insertvente.php");
                    final req = http.MultipartRequest('POST', url);
                    req.fields['client_id'] =
                        dialogClientSelectionne!; // Use the dialog's selected client
                    final res = await req.send();
                    if (res.statusCode == 200) {
                      await chargerVentes();
                      // On retrouve la dernière vente du client
                      final ventesClient = ventes
                          .where((v) =>
                              v["client_id"].toString() ==
                              dialogClientSelectionne)
                          .toList();
                      ventesClient.sort((a, b) => b["id_vente"]
                          .toString()
                          .compareTo(a["id_vente"].toString()));
                      final lastVente =
                          ventesClient.isNotEmpty ? ventesClient.first : null;
                      if (!mounted) return; // Check if widget is still mounted
                      Navigator.pop(ctx); // Pop the current dialog (new sale)
                      if (lastVente != null) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (!mounted)
                            return; // Check if widget is still mounted
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (context) => AddVenDetail(
                                  lastVente["id_vente"].toString()),
                            ),
                          );
                        });
                      }
                    } else {
                      if (!mounted) return; // Check if widget is still mounted
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Failed to create sale: ${res.statusCode}')),
                      );
                    }
                  },
                  child: const Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ventes.isEmpty
              ? const Center(child: Text("Aucune vente disponible."))
              : ListView.builder(
                  itemCount: ventes.length,
                  itemBuilder: (context, i) {
                    final v = ventes[i];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        leading:
                            const Icon(Icons.person, color: Colors.blueAccent),
                        title: Text(
                          v["client"] ?? "Client inconnu",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: v["date_vente"] != null
                            ? Text("Date: ${v["date_vente"]}")
                            : const Text("Date inconnue"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Supprimer cette vente",
                          onPressed: () =>
                              supprimerVente(v["id_vente"].toString()),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Lisventedet(
                                v["client"].toString(),
                                v["id_vente"].toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ajouterVente(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
