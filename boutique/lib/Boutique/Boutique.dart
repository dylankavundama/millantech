import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:stocktrue/Boutique/Detail.dart';

import 'package:stocktrue/ip.dart';

class Boutique extends StatefulWidget {
  const Boutique({super.key});

  @override
  State<Boutique> createState() => _BoutiqueState();
}

class _BoutiqueState extends State<Boutique> {
  List userdata = [];
  List filteredUserdata = [];
  bool isLoading = false;
  bool isGridMode = true;
  String? mail;

  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  String? selectedCategory; // New: To hold the selected category
  List<String> categories = []; // New: To store unique categories

  @override
  void initState() {
    super.initState();
    getrecord();
    searchController.addListener(() {
      filterProducts(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> getrecord() async {
    setState(() {
      isLoading = true;
    });
    var url = "$Adress_IP/produit/getproduit.php";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List reversedData = jsonDecode(response.body).reversed.toList();
        setState(() {
          userdata = reversedData;
          // Extract unique categories from fetched data
          // Ensure your product data has a 'categorie' field
          categories = userdata
              .map<String>((product) => product["categorie"].toString())
              .toSet()
              .toList();
          categories.sort(); // Optional: Sort categories alphabetically
          categories.insert(0, 'catégories'); // Add an "All" option
          selectedCategory = categories.first; // Set initial selected category
          filterProducts(searchQuery); // Filter initial data
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterProducts(String query) {
    setState(() {
      searchQuery = query;
      filteredUserdata = userdata.where((product) {
        final designation = product["designation"].toString().toLowerCase();
        final detail = product["detail"].toString().toLowerCase();
        final productCategory =
            product["categorie"].toString(); // Get product category
        final searchLower = query.toLowerCase();

        // Check if the product matches the search query
        bool matchesSearch =
            designation.contains(searchLower) || detail.contains(searchLower);

        // Check if the product matches the selected category
        // If "Toutes les catégories" is selected, all categories match.
        bool matchesCategory = selectedCategory == 'catégories' ||
            productCategory == selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _refreshData() async {
    await getrecord();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(screenH, screenW),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.orangeAccent,
      title: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          hintStyle: GoogleFonts.lato(color: Colors.white70),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    searchController.clear();
                    filterProducts("");
                  },
                )
              : null,
        ),
        style: GoogleFonts.lato(color: Colors.white, fontSize: 18),
        onChanged: (value) {
          filterProducts(value);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(isGridMode ? Icons.list : Icons.grid_view),
          onPressed: () {
            setState(() {
              isGridMode = !isGridMode;
            });
          },
          tooltip: isGridMode ? 'Vue liste' : 'Vue grille',
        ),
        if (categories
            .isNotEmpty) // Only show dropdown if categories are loaded
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              icon: const Icon(Icons.arrow_downward, color: Colors.white),
              elevation: 16,
              style: GoogleFonts.lato(color: Colors.white, fontSize: 16),
              dropdownColor: Colors.orangeAccent,
              underline: Container(), // Removes the default underline
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue;
                  filterProducts(
                      searchController.text); // Re-filter when category changes
                });
              },
              items: categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(double screenH, double screenW) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.orangeAccent,
      child: isLoading
          ? Center(
              child: Image.network(
                  height: 150,
                  'https://i.pinimg.com/originals/66/22/ab/6622ab37c6db6ac166dfec760a2f2939.gif'),
            )
          : filteredUserdata.isEmpty && !isLoading
              ? Center(
                  child: Text(
                    searchQuery.isNotEmpty
                        ? 'Aucun résultat pour "${searchQuery}"'
                        : 'Aucun produit disponible',
                    style: GoogleFonts.lato(fontSize: 18),
                  ),
                )
              : isGridMode
                  ? _buildGridView(screenH, screenW)
                  : _buildListView(screenH, screenW),
    );
  }

  Widget _buildGridView(double screenH, double screenW) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: filteredUserdata.length,
        itemBuilder: (context, index) {
          return _buildProductCard(context, index, screenH, screenW);
        },
      ),
    );
  }

  Widget _buildListView(double screenH, double screenW) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: filteredUserdata.length,
        itemBuilder: (context, index) {
          return _buildProductItem(context, index, screenH, screenW);
        },
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, int index, double screenH, double screenW) {
    return GestureDetector(
      onTap: () {
        _navigateToDetail(index);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                '${filteredUserdata[index]["image"]}',
                width: double.infinity,
                height: screenH * 0.18,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: screenH * 0.18,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image,
                      size: 50, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filteredUserdata[index]["designation"],
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filteredUserdata[index]["detail"],
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        '${filteredUserdata[index]["prixu"]} \$',
                        style: GoogleFonts.aBeeZee(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${filteredUserdata[index]["quantite"]}',
                        style: GoogleFonts.aBeeZee(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(
      BuildContext context, int index, double screenH, double screenW) {
    return GestureDetector(
      onTap: () {
        _navigateToDetail(index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: screenH * 0.18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Image.network(
                '${filteredUserdata[index]["image"]}',
                width: screenW * 0.35,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: screenW * 0.35,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image,
                      size: 50, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      filteredUserdata[index]["designation"],
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filteredUserdata[index]["detail"],
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${filteredUserdata[index]["prixu"]} \$',
                          style: GoogleFonts.aBeeZee(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${filteredUserdata[index]["quantite"]}',
                          style: GoogleFonts.aBeeZee(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: ((context) {
          return DetailproduitUser(
            filteredUserdata[index]["id_produit"].toString(),
            filteredUserdata[index]["designation"].toString(),
            filteredUserdata[index]["prixu"].toString(),
            filteredUserdata[index]["image"].toString(),
          );
        }),
      ),
    );
  }
}
