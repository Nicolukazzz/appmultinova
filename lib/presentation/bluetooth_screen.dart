import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:multinova/presentation/bluetooth_provider.dart';
import 'package:multinova/presentation/home_screen.dart';

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> _devicesList = [];
  bool _isScanning = false;
  bool _hasPermissions = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses =
          await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
            Permission.locationWhenInUse,
          ].request();

      setState(() {
        _hasPermissions = statuses.values.every((status) => status.isGranted);
      });

      if (_hasPermissions) {
        _startScan();
      } else {
        _showStatusMessage("Se requieren permisos para usar Bluetooth");
      }
    } else {
      PermissionStatus status = await Permission.bluetooth.request();
      setState(() => _hasPermissions = status.isGranted);
      if (_hasPermissions) _startScan();
    }
  }

  Future<bool> _checkBluetoothState() async {
    try {
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
        await Future.delayed(Duration(seconds: 1));
      }
      return true;
    } catch (e) {
      _showStatusMessage("Error al activar Bluetooth");
      return false;
    }
  }

  void _startScan() async {
    if (_isScanning) return;

    bool isBluetoothOn = await _checkBluetoothState();
    if (!isBluetoothOn) {
      _showStatusMessage("Active el Bluetooth en su dispositivo");
      return;
    }

    setState(() {
      _isScanning = true;
      _devicesList.clear();
    });

    try {
      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 10),
        androidScanMode: AndroidScanMode.lowLatency,
      );

      FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          _devicesList =
              results
                  .where((r) => r.device.name.isNotEmpty)
                  .map((r) => r.device)
                  .toList();
        });
      });

      await Future.delayed(Duration(seconds: 10));
    } catch (e) {
      _showStatusMessage("Error en escaneo: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
      await FlutterBluePlus.stopScan();
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isScanning = true;
      _statusMessage = "Conectando...";
    });

    try {
      await device.connect(autoConnect: false);
      await device.discoverServices();
      bluetoothProvider.setConnectedDevice(device);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      _showStatusMessage("Error al conectar: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _disconnectDevice() {
    Provider.of<BluetoothProvider>(context, listen: false).disconnectDevice();
    setState(() => _statusMessage = "Desconectado");
  }

  void _showStatusMessage(String message) {
    setState(() => _statusMessage = message);
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) setState(() => _statusMessage = null);
    });
  }

  Widget _buildPermissionWarning() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 60, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              "Permisos insuficientes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "La aplicación necesita permisos para buscar dispositivos Bluetooth",
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _requestPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: Text("Otorgar permisos"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green[600]),
            SizedBox(height: 16),
            Text("Buscando dispositivos..."),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDevicesFound() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No se encontraron dispositivos",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Asegúrese que los dispositivos estén encendidos y visibles",
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: Text("Reintentar"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Conexión Bluetooth",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[600],
        elevation: 4,
        actions: [
          if (bluetoothProvider.isConnected)
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: _disconnectDevice,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_statusMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text(_statusMessage!)),
                  ],
                ),
              ),
            SizedBox(height: 16),
            if (!_hasPermissions)
              _buildPermissionWarning()
            else if (_isScanning && _devicesList.isEmpty)
              _buildScanningIndicator()
            else if (_devicesList.isEmpty)
              _buildNoDevicesFound()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _devicesList.length,
                  itemBuilder: (context, index) {
                    final device = _devicesList[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: Colors.green[700],
                        ),
                        title: Text(device.name),
                        subtitle: Text(device.remoteId.toString()),
                        trailing: Icon(Icons.link, color: Colors.grey[600]),
                        onTap: () => _connectToDevice(device),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton:
          !bluetoothProvider.isConnected && _hasPermissions
              ? FloatingActionButton(
                child: Icon(
                  _isScanning ? Icons.hourglass_top : Icons.refresh,
                  color: Colors.white,
                ),
                onPressed: _isScanning ? null : _startScan,
                backgroundColor: Colors.green[600],
              )
              : null,
    );
  }
}
