import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;

  void setConnectedDevice(BluetoothDevice device) {
    _connectedDevice = device;
    _isConnected = true;
    notifyListeners();
  }

  void disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _isConnected = false;
      notifyListeners();
    }
  }
}
