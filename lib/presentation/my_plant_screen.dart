import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:multinova/presentation/bluetooth_provider.dart';
import 'dart:convert';
import 'dart:async';

class MyPlantScreen extends StatefulWidget {
  @override
  _MyPlantScreenState createState() => _MyPlantScreenState();
}

class _MyPlantScreenState extends State<MyPlantScreen> {
  static const UART_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const UART_TX_CHAR_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  static const UART_RX_CHAR_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

  BluetoothCharacteristic? _uartRxCharacteristic;
  BluetoothCharacteristic? _uartTxCharacteristic;
  bool _isLoading = false;
  StreamSubscription<List<int>>? _dataSubscription;

  double _humidity = 0;
  double _light = 0;
  double _temperature = 0;
  double _ph = 0;
  String _connectionStatus = "Conectando...";
  String _plantName = "Planta Multinova";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupBluetooth();
    });
  }

  Future<void> _setupBluetooth() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(
      context,
      listen: false,
    );

    if (!bluetoothProvider.isConnected) {
      setState(() => _connectionStatus = 'Dispositivo no conectado');
      return;
    }

    try {
      final device = bluetoothProvider.connectedDevice!;
      if (!device.isConnected) {
        await device.connect(autoConnect: false);
        await Future.delayed(Duration(seconds: 1));
      }

      setState(() => _connectionStatus = 'Descubriendo servicios...');
      final services = await device.discoverServices();

      BluetoothService? uartService;
      try {
        uartService = services.firstWhere(
          (s) =>
              s.uuid.toString().toLowerCase() ==
              UART_SERVICE_UUID.toLowerCase(),
        );
      } catch (e) {
        setState(() => _connectionStatus = 'Servicio UART no encontrado');
        return;
      }

      try {
        _uartRxCharacteristic = uartService.characteristics.firstWhere(
          (c) =>
              c.uuid.toString().toLowerCase() ==
              UART_RX_CHAR_UUID.toLowerCase(),
        );
      } catch (e) {
        setState(() => _connectionStatus = 'Característica RX no encontrada');
        return;
      }

      try {
        _uartTxCharacteristic = uartService.characteristics.firstWhere(
          (c) =>
              c.uuid.toString().toLowerCase() ==
              UART_TX_CHAR_UUID.toLowerCase(),
        );
      } catch (e) {
        setState(() => _connectionStatus = 'Característica TX no encontrada');
        return;
      }

      await _uartTxCharacteristic!.setNotifyValue(true);
      _dataSubscription = _uartTxCharacteristic!.value.listen(
        _processSensorData,
      );

      setState(() => _connectionStatus = 'Listo para medir');
    } catch (e) {
      setState(() => _connectionStatus = 'Error: ${e.toString()}');
    }
  }

  void _processSensorData(List<int> data) {
    try {
      final sensorData = json.decode(String.fromCharCodes(data));
      setState(() {
        _humidity = sensorData["humidity"]?.toDouble() ?? 0;
        _light = sensorData["light"]?.toDouble() ?? 0;
        _temperature = sensorData["temperature"]?.toDouble() ?? 0;
        _ph = sensorData["ph"]?.toDouble() ?? 0;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Datos actualizados"),
          backgroundColor: const Color.fromARGB(255, 104, 124, 206),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error en formato de datos"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takeMeasurements() async {
    if (_uartRxCharacteristic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bluetooth no configurado correctamente"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _uartRxCharacteristic!.write(utf8.encode('2\n'));
      await Future.delayed(Duration(seconds: 15));

      if (_isLoading) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("El dispositivo no respondió"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Multinova", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 104, 124, 206),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              color: const Color.fromARGB(255, 104, 124, 206),
              child: Row(
                children: [
                  Icon(Icons.eco, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _plantName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _connectionStatus,
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sensor Data
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildSensorCard(
                    icon: Icons.opacity,
                    title: "Humedad",
                    value: "${_humidity.toStringAsFixed(1)}%",
                    color: Colors.blue,
                  ),
                  SizedBox(height: 12),
                  _buildSensorCard(
                    icon: Icons.wb_sunny,
                    title: "Luz",
                    value: "${_light.toStringAsFixed(1)} lux",
                    color: Colors.amber,
                  ),
                  SizedBox(height: 12),
                  _buildSensorCard(
                    icon: Icons.thermostat,
                    title: "Temperatura",
                    value: "${_temperature.toStringAsFixed(1)}°C",
                    color: Colors.red,
                  ),
                  SizedBox(height: 12),
                  _buildSensorCard(
                    icon: Icons.science,
                    title: "PH",
                    value: _ph.toStringAsFixed(1),
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _takeMeasurements,
          backgroundColor: const Color.fromARGB(255, 104, 124, 206),
          icon:
              _isLoading
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Icon(Icons.play_arrow),
          label: Text(_isLoading ? "MEDICIÓN EN CURSO" : "INICIAR MEDICIÓN"),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}
