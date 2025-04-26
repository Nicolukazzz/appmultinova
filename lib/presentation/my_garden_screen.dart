import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
      ).showSnackBar(SnackBar(content: Text('Error al cargar mi jardín: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        centerTitle: true,
        title: const Text(
          'Mi Jardín',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _myGarden.isEmpty
              ? const Center(child: Text('No has agregado plantas.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myGarden.length,
                itemBuilder: (context, index) {
                  final key = _myGarden.keys.elementAt(index);
                  final plant = _myGarden[key];

                  return _buildPlantCard(
                    plant['commonName'] ?? 'Sin nombre',
                    plant['scientificName'] ?? 'Sin nombre científico',
                    plant['category'] ?? 'Sin categoría',
                  );
                },
              ),
    );
  }

  Widget _buildPlantCard(
    String commonName,
    String scientificName,
    String category,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            'Categoría: $category',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
