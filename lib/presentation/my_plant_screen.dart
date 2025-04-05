import 'package:flutter/material.dart';

class MyPlantScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mi Planta", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(),
        child: Center(
          child: Card(
            margin: EdgeInsets.all(20),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🌱", style: TextStyle(fontSize: 80)),
                  SizedBox(height: 20),
                  _buildInfoRow("Nombre", "Planta Feliz"),
                  _buildInfoRow("Humedad", "70%"),
                  _buildInfoRow("Luz", "90%"),
                  _buildInfoRow("Temperatura", "25°C"),
                  _buildInfoRow("PH", "6.5"),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[700],
        child: Icon(Icons.speed, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(
                    "Tomando mediciones",
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[700]!,
                        ),
                      ),
                      SizedBox(height: 15),
                      Text("Sensores en curso..."),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        "Cerrar",
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
          );
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Datos actualizados"),
                backgroundColor: Colors.blue[700],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          Text(value, style: TextStyle(fontSize: 18, color: Colors.blue[800])),
        ],
      ),
    );
  }
}
