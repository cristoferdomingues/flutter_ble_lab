import 'dart:async';
import 'dart:typed_data';

import 'package:blemulator/blemulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:risecx_ble/CGM.dart';
import 'package:risecx_ble/SensorTag.dart';

typedef TestedFunction = Future<void> Function();

class BluetoothProvider with ChangeNotifier {
  //EMULATOR
  Blemulator _blemulator = Blemulator();
  //END
  BleManager _bleManager = BleManager();
  bool scanning = false;
  bool connected = false;
  List<Peripheral> scannedPeripherals = new List<Peripheral>();
  Peripheral connectedPeripheral;
  double temperature;

  BluetoothProvider.initialize() {
    initializeBLE();
  }

  Future<void> initializeBLE() async {
    _blemulator.addSimulatedPeripheral(SensorTag());
    _blemulator.addSimulatedPeripheral(CGM());
    _blemulator.simulate();
    await _bleManager.createClient();
    _bleManager.observeBluetoothState().listen((btState) {
      print('Bluetooth State $btState');
      //do your BT logic, open different screen, etc.
    });
  }
  
  /* Bluetooth Provider Refactored */

  Future<void> disconnectFromPeripheral() async {
    await _runWithErrorHandling(() async {
      if (connected) await connectedPeripheral.disconnectOrCancelConnection();
      connected = await connectedPeripheral.isConnected();
      connectedPeripheral = null;
      notifyListeners();
    });
  }

  Future<void> connectToPeripheral(Peripheral _peripheral) async {
    await _runWithErrorHandling(() async {
      if (connected == false) {
        await _peripheral.connect();
        connectedPeripheral = _peripheral;
      }

      connected = await _peripheral.isConnected();
      _monitoringFromPeripheral();
      Future.delayed(Duration(seconds: 1));
    });
  }

  Future<void> scanPeripherals() async {
    await _runWithErrorHandling(() async {
      _toggleScanningStatus(true);
      _bleManager.startPeripheralScan().listen((scanResult) async {
        if (scannedPeripherals.isEmpty ||
            scannedPeripherals.firstWhere(
                    (scannedPeripheral) =>
                        scanResult.peripheral.identifier ==
                        scannedPeripheral.identifier,
                    orElse: () => null) ==
                null) {
          scannedPeripherals.add(scanResult.peripheral);
        }
        Timer(Duration(seconds: 15), () {
          _bleManager.stopPeripheralScan;
          _toggleScanningStatus(false);
        });
      });
    });
  }

  void _toggleScanningStatus(bool status) {
    scanning = status;
    notifyListeners();
  }

  void _monitoringFromPeripheral() async {
    await connectedPeripheral.discoverAllServicesAndCharacteristics();
    List<Service> services = await connectedPeripheral.services();
    List<Characteristic> characteristics =
        await services.first?.characteristics();
    characteristics.first.monitor().listen((event) {
      print(
          '${connectedPeripheral.identifier} monitoring ${_convertToTemperature(event)} C');
      temperature = _convertToTemperature(event);
      notifyListeners();
    });
  }

  Future<void> _runWithErrorHandling(TestedFunction testedFunction) async {
    try {
      await testedFunction();
    } on BleError catch (e) {
      print("BleError caught: ${e.errorCode.value} ${e.reason}");
    } catch (e) {
      if (e is Error) {
        debugPrintStack(stackTrace: e.stackTrace);
      }
      print("${e.runtimeType}: $e");
    }
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
