import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'plant_detail_screen.dart';

class PlantsListScreen extends StatefulWidget {
  const PlantsListScreen({Key? key}) : super(key: key);

  @override
  State<PlantsListScreen> createState() => _PlantsListScreenState();
}

class _PlantsListScreenState extends State<PlantsListScreen> {
  final DatabaseReference _plantsRef = FirebaseDatabase.instance.ref('plants');
  Map<String, dynamic> _plants = {};
  Map<String, dynamic> _filteredPlants = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPlants();
    _searchController.addListener(_filterPlants);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlants() async {
    try {
      final snapshot = await _plantsRef.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _plants = data;
          _filteredPlants = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar plantas: $e')));
    }
  }

  void _filterPlants() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPlants = {};

      _plants.forEach((key, value) {
        // Conversión segura del valor a Map
        final plant = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);

        final name = plant['commonName']?.toString().toLowerCase() ?? '';
        final sciName = plant['scientificName']?.toString().toLowerCase() ?? '';
        final category = plant['category']?.toString().toLowerCase() ?? '';

        if (name.contains(query) ||
            sciName.contains(query) ||
            category.contains(query)) {
          _filteredPlants[key] = plant;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        centerTitle: true,
        title: const Text(
          'Plantas disponibles',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar plantas...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                              _filterPlants();
                            },
                          )
                          : null,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          // Lista de plantas
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPlants.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _plants.isEmpty
                                ? 'No se encontraron plantas'
                                : 'No hay coincidencias',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _filteredPlants.length,
                      itemBuilder: (context, index) {
                        final key = _filteredPlants.keys.elementAt(index);
                        final plant = _filteredPlants[key];

                        return _buildPlantCard(
                          plant['commonName'] ?? 'Sin nombre',
                          plant['scientificName'] ?? 'Sin nombre científico',
                          plant['category'] ?? 'Sin categoría',
                          onTap: () async {
                            final plantToAdd = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PlantDetailScreen(
                                      plantData: Map<String, dynamic>.from(
                                        plant,
                                      ),
                                    ),
                              ),
                            );

                            if (plantToAdd != null) {
                              final gardenRef = FirebaseDatabase.instance.ref(
                                'my_garden',
                              );
                              await gardenRef.push().set(plantToAdd);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '¡Planta agregada a tu jardín!',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(
    String commonName,
    String scientificName,
    String category, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_florist,
                color: Colors.green[600],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commonName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scientificName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
