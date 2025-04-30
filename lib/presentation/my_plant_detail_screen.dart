import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:multinova/presentation/bluetooth_provider.dart';

class PlantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;

  const PlantDetailScreen({Key? key, required this.plantData})
    : super(key: key);

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  static const UART_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const UART_TX_CHAR_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  static const UART_RX_CHAR_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

  BluetoothCharacteristic? _uartRxCharacteristic;
  BluetoothCharacteristic? _uartTxCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;

  bool _isLoading = false;
  String _connectionStatus = "Conectando...";

  double _humidity = 0;
  double _light = 0;
  double _temperature = 0;
  double _ph = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupBluetooth());
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
        await Future.delayed(const Duration(seconds: 1));
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
        _humidity = (sensorData["humidity"] ?? 0).toDouble();
        _light = (sensorData["light"] ?? 0).toDouble();
        _temperature = (sensorData["temperature"] ?? 0).toDouble();
        _ph = (sensorData["ph"] ?? 0).toDouble();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Datos actualizados"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al leer datos"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takeMeasurements() async {
    if (_uartRxCharacteristic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bluetooth no configurado"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _uartRxCharacteristic!.write(utf8.encode('2\n'));
      await Future.delayed(const Duration(seconds: 15));
      if (_isLoading) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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

  Map<String, dynamic> _parseMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Widget _buildConditionCard(
    String title,
    String range,
    String optimal,
    IconData icon,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              range,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
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

  Widget _buildSensorCard(
    String title,
    double value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${value.toStringAsFixed(1)} $unit",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green[800],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plantData;
    final commonName = plant['commonName'] ?? 'Sin nombre';
    final scientificName = plant['scientificName'] ?? 'Sin nombre científico';
    final optimal = _parseMap(plant['optimalConditions']);

    final tempOpt = _parseMap(optimal['temperature']);
    final humOpt = _parseMap(optimal['humidity']);
    final lightOpt = _parseMap(optimal['light']);
    final phOpt = _parseMap(optimal['ph']);

    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        elevation: 0,
        centerTitle: true,
        title: Text(
          commonName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la planta
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.eco,
                        size: 40,
                        color: Colors.green[600],
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.bluetooth,
                                color: Colors.green[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _connectionStatus,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        _connectionStatus.contains('Error')
                                            ? Colors.red
                                            : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Condiciones Óptimas'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildConditionCard(
                  'Temperatura',
                  '${tempOpt['min']?.toStringAsFixed(1) ?? 'N/A'} - ${tempOpt['max']?.toStringAsFixed(1) ?? 'N/A'}°C',
                  'Óptima: ${tempOpt['optimal']?.toStringAsFixed(1) ?? 'N/A'}°C',
                  Icons.thermostat,
                ),
                _buildConditionCard(
                  'Humedad',
                  '${humOpt['min']?.toStringAsFixed(1) ?? 'N/A'} - ${humOpt['max']?.toStringAsFixed(1) ?? 'N/A'}%',
                  'Óptima: ${humOpt['optimal']?.toStringAsFixed(1) ?? 'N/A'}%',
                  Icons.water_drop,
                ),
                _buildConditionCard(
                  'Luz',
                  '${lightOpt['min']?.toStringAsFixed(1) ?? 'N/A'} - ${lightOpt['max']?.toStringAsFixed(1) ?? 'N/A'} lux',
                  'Óptima: ${lightOpt['optimal']?.toStringAsFixed(1) ?? 'N/A'} lux',
                  Icons.light_mode,
                ),
                _buildConditionCard(
                  'pH',
                  '${phOpt['min']?.toStringAsFixed(1) ?? 'N/A'} - ${phOpt['max']?.toStringAsFixed(1) ?? 'N/A'}',
                  'Óptimo: ${phOpt['optimal']?.toStringAsFixed(1) ?? 'N/A'}',
                  Icons.science,
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Lecturas del Sensor'),
            const SizedBox(height: 12),
            _buildSensorCard(
              'Temperatura',
              _temperature,
              '°C',
              Icons.thermostat,
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildSensorCard(
              'Humedad',
              _humidity,
              '%',
              Icons.water_drop,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildSensorCard(
              'Luz',
              _light,
              'lux',
              Icons.light_mode,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildSensorCard('pH', _ph, '', Icons.science, Colors.purple),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _takeMeasurements,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Icon(Icons.sensors, color: Colors.white),
        label: Text(
          _isLoading ? "Midiendo..." : "Medir sensores",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[600],
        elevation: 2,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
