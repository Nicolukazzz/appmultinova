import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:async';

class SensorDataScreen extends StatefulWidget {
  final String plantName;

  const SensorDataScreen({Key? key, required this.plantName}) : super(key: key);

  @override
  _SensorDataScreenState createState() => _SensorDataScreenState();
}

class _SensorDataScreenState extends State<SensorDataScreen> {
  static const String uartServiceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String uartTxCharUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String uartRxCharUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

  BluetoothCharacteristic? _uartRxCharacteristic;
  bool _isLoading = false;
  String _statusMessage = 'Presiona para medir';
  List<String> _recommendations = [];

  double _humidity = 0;
  double _light = 0;
  double _temperature = 0;
  double _ph = 0;

  @override
  void initState() {
    super.initState();
    _setupBluetooth();
  }

  Future<void> _setupBluetooth() async {
    try {
      if (!await FlutterBluePlus.isOn) {
        setState(() => _statusMessage = 'Bluetooth no activado');
        return;
      }

      BluetoothDevice? device;
      var connectedDevices = await FlutterBluePlus.connectedDevices;
      if (connectedDevices.isNotEmpty) {
        device = connectedDevices.first;
      } else {
        setState(() => _statusMessage = 'No hay dispositivos conectados');
        return;
      }

      if (!device.isConnected) {
        await device.connect(autoConnect: false);
        await Future.delayed(Duration(seconds: 1));
      }

      List<BluetoothService> services = await device.discoverServices();
      BluetoothService? uartService;
      try {
        uartService = services.firstWhere(
          (s) =>
              s.uuid.toString().toLowerCase() == uartServiceUuid.toLowerCase(),
        );
      } catch (_) {
        setState(() => _statusMessage = 'Servicio UART no encontrado');
        return;
      }

      try {
        _uartRxCharacteristic = uartService.characteristics.firstWhere(
          (c) =>
              c.uuid.toString().toLowerCase() == uartRxCharUuid.toLowerCase(),
        );
      } catch (_) {
        setState(() => _statusMessage = 'Característica UART RX no encontrada');
        return;
      }

      BluetoothCharacteristic? txCharacteristic;
      try {
        txCharacteristic = uartService.characteristics.firstWhere(
          (c) =>
              c.uuid.toString().toLowerCase() == uartTxCharUuid.toLowerCase(),
        );
      } catch (_) {
        setState(() => _statusMessage = 'Característica UART TX no encontrada');
        return;
      }

      await txCharacteristic.setNotifyValue(true);
      txCharacteristic.value.listen(_processSensorData);

      setState(() => _statusMessage = 'Listo para medir');
    } catch (e) {
      setState(() => _statusMessage = 'Error: ${e.toString()}');
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
        _statusMessage = "Medición completada";
        _generateRecommendations();
      });
    } catch (e) {
      setState(() => _statusMessage = "Error en formato JSON");
    }
  }

  void _generateRecommendations() {
    final recommendations = <String>[];
    if (_humidity < 40) recommendations.add("Agrega agua a la planta");
    if (_light < 50) recommendations.add("Mueve a lugar más iluminado");
    if (_temperature < 18) recommendations.add("Ambiente muy frío");
    if (_ph < 5.5 || _ph > 7) recommendations.add("Ajusta el pH del suelo");

    setState(() => _recommendations = recommendations);
  }

  Future<void> _takeMeasurements() async {
    if (_uartRxCharacteristic == null) {
      setState(() => _statusMessage = 'Bluetooth no configurado');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Midiendo...';
      _recommendations.clear();
    });

    try {
      await _uartRxCharacteristic!.write(utf8.encode('2\n'));
      await Future.delayed(Duration(seconds: 15));
      if (_isLoading) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Timeout: Sin respuesta";
        });
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.plantName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_statusMessage),
            ElevatedButton(onPressed: _takeMeasurements, child: Text("Medir")),
            if (_recommendations.isNotEmpty)
              ..._recommendations.map((rec) => Text(rec)).toList(),
          ],
        ),
      ),
    );
  }
}
