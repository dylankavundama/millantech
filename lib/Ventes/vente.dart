import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/Util.dart';
import 'package:stocktrue/Ventes/Detailsventes/AddVentedetail.dart';
import 'package:stocktrue/Ventes/ListdetVente.dart';
import '../ip.dart';

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
        setState(() => ventes = List.from(jsonDecode(response.body)));
      }
    } catch (_) {}
  }

  Future<void> chargerClients() async {
    try {
      final url = Uri.parse("$Adress_IP/CLIENT/getclient.php");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() => clients = List.from(jsonDecode(response.body)));
      }
    } catch (_) {}
  }

  Future<void> supprimerVente(String idVente) async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("$Adress_IP/VENTE/deletevente.php");
      await http.post(url, body: {"id": idVente});
      await chargerVentes();
    } catch (_) {}
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
              if (nomCtrl.text.trim().isEmpty || telCtrl.text.trim().isEmpty)
                return;
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
                  orElse: () => null,
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
                  }
                }
              }
              Navigator.pop(ctx); // Ferme le dialogue ajout client
              if (venteDialogContext != null) {
                Navigator.pop(
                    venteDialogContext); // Ferme aussi le dialogue nouvelle vente
              }
              // Rafraîchir la page Ventes après le pop
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
    clientSelectionne = null;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouvelle vente"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: clientSelectionne,
              items: clients.map<DropdownMenuItem<String>>((c) {
                return DropdownMenuItem(
                  value: c["id_client"].toString(),
                  child: Text(c["noms"] ?? "Client inconnu"),
                );
              }).toList(),
              onChanged: (v) => setState(() => clientSelectionne = v),
              decoration: const InputDecoration(labelText: "Client"),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.person_add, color: Colors.orange),
              label: const Text("Ajouter un client"),
              onPressed: () async {
                await ajouterClient(context, venteDialogContext: ctx);
                // Pas besoin de relancer ajouterVente, tout est fermé
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
              if (clientSelectionne == null) return;
              // Vérifier le stock global avant d'enregistrer la vente
              final stockOk = await verifierStockGlobal();
              if (!stockOk) {
                // ignore: use_build_context_synchronously
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
                Navigator.pop(ctx); // Ferme le dialogue de création de vente
                return;
              }
              final url = Uri.parse("$Adress_IP/VENTE/insertvente.php");
              final req = http.MultipartRequest('POST', url);
              req.fields['client_id'] = clientSelectionne!;
              final res = await req.send();
              if (res.statusCode == 200) {
                await chargerVentes();
                // On retrouve la dernière vente du client
                final ventesClient = ventes
                    .where(
                        (v) => v["client_id"].toString() == clientSelectionne)
                    .toList();
                ventesClient.sort((a, b) => b["id_vente"]
                    .toString()
                    .compareTo(a["id_vente"].toString()));
                final lastVente =
                    ventesClient.isNotEmpty ? ventesClient.first : null;
                Navigator.pop(ctx);
                if (lastVente != null) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AddVenDetail(lastVente["id_vente"].toString()),
                      ),
                    );
                  });
                }
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ventes")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ventes.isEmpty
              ? const Center(child: Text("Aucune vente disponible."))
              : ListView.builder(
                  itemCount: ventes.length,
                  itemBuilder: (context, i) {
                    final v = ventes[i];
                    return ListTile(
                      title: Text(v["client"] ?? "Client inconnu"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
