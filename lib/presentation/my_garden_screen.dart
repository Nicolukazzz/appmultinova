import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'my_plant_detail_screen.dart';

class MyGardenScreen extends StatefulWidget {
  const MyGardenScreen({Key? key}) : super(key: key);

  @override
  State<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends State<MyGardenScreen> {
  final DatabaseReference _gardenRef = FirebaseDatabase.instance.ref(
    'my_garden',
  );
  Map<String, dynamic> _myGarden = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyGarden();
  }

  Future<void> _fetchMyGarden() async {
    try {
      final snapshot = await _gardenRef.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _myGarden = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar mi jardín: $e')));
    }
  }

  Future<void> _deletePlant(String key) async {
    try {
      await _gardenRef.child(key).remove();
      setState(() => _myGarden.remove(key));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Planta eliminada')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar planta: $e')));
    }
  }

  void _showDeleteDialog(String key, String name) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar planta'),
            content: Text('¿Deseas eliminar "$name" de tu jardín?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _deletePlant(key);
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f4f3),
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        centerTitle: true,
        title: const Text(
          'Mi Jardín',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 2,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _myGarden.isEmpty
              ? _buildEmptyGarden()
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myGarden.length,
                itemBuilder: (context, index) {
                  final key = _myGarden.keys.elementAt(index);
                  final plant = Map<String, dynamic>.from(
                    _myGarden[key] as Map,
                  );

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlantDetailScreen(plantData: plant),
                        ),
                      );
                    },
                    onLongPress:
                        () => _showDeleteDialog(
                          key,
                          plant['commonName'] ?? 'Esta planta',
                        ),
                    child: _buildPlantCard(
                      plant['commonName'] ?? 'Sin nombre',
                      plant['scientificName'] ?? 'Sin nombre científico',
                      plant['category'] ?? 'Sin categoría',
                      plant['imageUrl'] ?? '',
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildEmptyGarden() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_florist, size: 100, color: Colors.green[300]),
          const SizedBox(height: 20),
          const Text(
            'Tu jardín está vacío',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPlantCard(
    String commonName,
    String scientificName,
    String category,
    String imageUrl,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child:
                imageUrl.isNotEmpty
                    ? Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                    : Container(
                      width: 100,
                      height: 100,
                      color: Colors.green[100],
                      child: const Icon(
                        Icons.local_florist,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commonName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scientificName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
