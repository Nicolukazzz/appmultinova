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

      final uartService = services.firstWhere(
        (s) =>
            s.uuid.toString().toLowerCase() == UART_SERVICE_UUID.toLowerCase(),
        orElse: () => throw Exception('Servicio UART no encontrado'),
      );

      _uartRxCharacteristic = uartService.characteristics.firstWhere(
        (c) =>
            c.uuid.toString().toLowerCase() == UART_RX_CHAR_UUID.toLowerCase(),
        orElse: () => throw Exception('Característica RX no encontrada'),
      );

      _uartTxCharacteristic = uartService.characteristics.firstWhere(
        (c) =>
            c.uuid.toString().toLowerCase() == UART_TX_CHAR_UUID.toLowerCase(),
        orElse: () => throw Exception('Característica TX no encontrada'),
      );

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
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al leer datos"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takeMeasurements() async {
    if (_uartRxCharacteristic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bluetooth no configurado"),
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
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff6f6f6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          "Mi Planta",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green[100],
                  radius: 28,
                  child: Icon(Icons.eco, size: 28, color: Colors.green[700]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _plantName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _connectionStatus,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSensorCard(
                    "Humedad",
                    "${_humidity.toStringAsFixed(1)}%",
                    Icons.water_drop,
                  ),
                  _buildSensorCard(
                    "Luz",
                    "${_light.toStringAsFixed(1)} lux",
                    Icons.wb_sunny,
                  ),
                  _buildSensorCard(
                    "Temperatura",
                    "${_temperature.toStringAsFixed(1)}°C",
                    Icons.thermostat,
                  ),
                  _buildSensorCard(
                    "pH",
                    "${_ph.toStringAsFixed(1)}",
                    Icons.science,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isLoading ? null : _takeMeasurements,
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
                  : Icon(Icons.play_arrow, color: Colors.white),
          label: Text(
            _isLoading ? "Midiendo..." : "Iniciar medición",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green[50],
            child: Icon(icon, color: Colors.green[600]),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
