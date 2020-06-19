import 'dart:async';
import 'dart:typed_data';

import 'package:blemulator/blemulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:risecx_ble/SensorTag.dart';

class BluetoothProvider with ChangeNotifier {
  //EMULATOR
  Blemulator _blemulator = Blemulator();
  //END
  BleManager _bleManager = BleManager();
  bool scanning = false;
  bool connected = false;
  Peripheral peripheral;
  double temperature;

  BluetoothProvider.initialize() {
    initializeBLE();
    //  searchForDevices();
  }

  Future<void> initializeBLE() async {
    _blemulator.addSimulatedPeripheral(SensorTag());
    _blemulator.simulate();
    await _bleManager.createClient();
    _bleManager.observeBluetoothState().listen((btState) {
      print('Bluetooth State $btState');
      //do your BT logic, open different screen, etc.
    });
  }

  Future<void> searchForDevices() async {
    _toggleScanningStatus(true);
    try {
      _bleManager.startPeripheralScan().listen((scanResult) async {
        //Scan one peripheral and stop scanning
        print(
            "Scanned Peripheral ${scanResult.peripheral.name}, RSSI ${scanResult.rssi}");
        peripheral = scanResult.peripheral;

        await _connectToPeripheral();

        peripheral
            .observeConnectionState(
                emitCurrentValue: true, completeOnDisconnect: true)
            .listen((connectionState) {
          print(
              "Peripheral ${scanResult.peripheral.identifier} connection state is $connectionState");
        });

        await peripheral.discoverAllServicesAndCharacteristics();

        List<Service> services = await peripheral.services();

        List<Characteristic> characteristics =
            await services[0]?.characteristics();

        characteristics[0].monitor().listen((event) {
          print(
              '${scanResult.peripheral.identifier} monitoring ${_convertToTemperature(event)} C');
              temperature = _convertToTemperature(event);
              notifyListeners();
        });
        _bleManager.stopPeripheralScan();
        _toggleScanningStatus(false);
        notifyListeners();
      });
    } catch (e) {
      _toggleScanningStatus(false);
      notifyListeners();
      throw e;
    }
  }

  Future<void> _connectToPeripheral() async {
    if (connected == false) await peripheral.connect();
    connected = await peripheral.isConnected();
    Future.delayed(Duration(seconds: 1));
  }

  Future<void> disconnectFromPeripheral() async {
    if (connected) await peripheral.disconnectOrCancelConnection();
    connected = await peripheral.isConnected();
  }

  void _toggleScanningStatus(bool status) {
    scanning = status;
    notifyListeners();
  }

  double _convertToTemperature(Uint8List rawTemperatureBytes) {
    const double SCALE_LSB = 0.03125;
    int rawTemp = rawTemperatureBytes[3] << 8 | rawTemperatureBytes[2];
    return ((rawTemp) >> 2) * SCALE_LSB;
  }

  @override
  void dispose() {
    super.dispose();
    _bleManager.destroyClient();
  }
}
