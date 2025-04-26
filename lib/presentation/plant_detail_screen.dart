import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PlantDetailScreen extends StatelessWidget {
  final Map<Object?, Object?> plantData;

  const PlantDetailScreen({Key? key, required this.plantData})
    : super(key: key);

  // Método para convertir los datos a Map<String, dynamic>
  Map<String, dynamic> get parsedData {
    return plantData.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  Widget build(BuildContext context) {
    final commonName = parsedData['commonName']?.toString() ?? 'Sin nombre';
    final scientificName =
        parsedData['scientificName']?.toString() ?? 'Sin nombre científico';
    final category = parsedData['category']?.toString() ?? 'Sin categoría';
    final optimalConditions = _parseNestedMap(parsedData['optimalConditions']);
    final careTips = _parseNestedMap(parsedData['careTips']);
    final environment = _parseNestedMap(parsedData['environment']);

    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        title: Text(
          commonName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 80, // Espacio para el botón
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlantHeader(scientificName, category),
                  SizedBox(height: 24),

                  _buildSectionTitle('Condiciones Óptimas'),
                  SizedBox(height: 12),
                  _buildConditionsGrid(optimalConditions),
                  SizedBox(height: 24),

                  _buildSectionTitle('Cuidados'),
                  SizedBox(height: 12),
                  _buildCareTips(careTips),
                  SizedBox(height: 24),

                  _buildSectionTitle('Entorno Ideal'),
                  SizedBox(height: 12),
                  _buildEnvironmentInfo(environment),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Botón fijo en la parte inferior
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Agregar a mi jardín',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _parseNestedMap(dynamic data) {
    if (data == null) return {};
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  Widget _buildPlantHeader(String scientificName, String category) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.eco, size: 40, color: Colors.green[600]),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scientificName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green[800],
      ),
    );
  }

  Widget _buildConditionsGrid(Map<String, dynamic> conditions) {
    final temperature = _parseNestedMap(conditions['temperature']);
    final humidity = _parseNestedMap(conditions['humidity']);
    final light = _parseNestedMap(conditions['light']);
    final ph = _parseNestedMap(conditions['ph']);

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildConditionCard(
          '🌡️ Temperatura',
          '${temperature['min'] ?? 'N/A'} - ${temperature['max'] ?? 'N/A'}°C',
          'Óptima: ${temperature['optimal'] ?? 'N/A'}°C',
        ),
        _buildConditionCard(
          '💧 Humedad',
          '${humidity['min'] ?? 'N/A'} - ${humidity['max'] ?? 'N/A'}%',
          'Óptima: ${humidity['optimal'] ?? 'N/A'}%',
        ),
        _buildConditionCard(
          '☀️ Luz',
          '${light['min'] ?? 'N/A'} - ${light['max'] ?? 'N/A'} lux',
          'Óptima: ${light['optimal'] ?? 'N/A'} lux',
        ),
        _buildConditionCard(
          '🧪 pH',
          '${ph['min'] ?? 'N/A'} - ${ph['max'] ?? 'N/A'}',
          'Óptimo: ${ph['optimal'] ?? 'N/A'}',
        ),
      ],
    );
  }

  Widget _buildConditionCard(String title, String range, String optimal) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              range,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            Text(
              optimal,
              style: TextStyle(
                fontSize: 13,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareTips(Map<String, dynamic> careTips) {
    final watering = _parseNestedMap(careTips['watering']);
    final soilType = careTips['soilType']?.toString() ?? 'No especificado';
    final potType = careTips['potType']?.toString() ?? 'No especificado';

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              '💦 Riego',
              '${watering['amount'] ?? 'N/A'} ml ${watering['frequency'] ?? 'N/A'}',
            ),
            Divider(height: 24, thickness: 1, color: Colors.grey[200]),
            _buildInfoRow('🌱 Tipo de suelo', soilType),
            Divider(height: 24, thickness: 1, color: Colors.grey[200]),
            _buildInfoRow('🏺 Tipo de maceta', potType),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(child: Text(value, style: TextStyle(color: Colors.grey[600]))),
      ],
    );
  }

  Widget _buildEnvironmentInfo(Map<String, dynamic> environment) {
    final zone = environment['zone']?.toString() ?? 'No especificada';
    final lightCondition =
        environment['lightCondition']?.toString() ?? 'No especificada';

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('📍 Zona', _translateZone(zone)),
            Divider(height: 24, thickness: 1, color: Colors.grey[200]),
            _buildInfoRow(
              '☀️ Condición de luz',
              _translateLightCondition(lightCondition),
            ),
          ],
        ),
      ),
    );
  }

  String _translateZone(String zone) {
    switch (zone) {
      case 'tropical':
        return 'Tropical';
      case 'temperate':
        return 'Templada';
      case 'arid':
        return 'Árida';
      default:
        return zone;
    }
  }

  String _translateLightCondition(String condition) {
    switch (condition) {
      case 'partial_shade':
        return 'Sombra parcial';
      case 'full_sun':
        return 'Sol pleno';
      case 'shade':
        return 'Sombra';
      default:
        return condition;
    }
  }
}
