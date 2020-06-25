import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:provider/provider.dart';
import 'package:risecx_ble/bluetoohBtnWidget.dart';
import 'package:risecx_ble/peripheralsListWidget.dart';
import 'package:risecx_ble/providers/bluetooth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider.value(value: BluetoothProvider.initialize())
  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'RiseCx BLE Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _connectedDevices = 0;
  Peripheral _connectedPeripheral;
  double _temperature = 0;
  List<Peripheral> _scannedPeripherals;
  BluetoothProvider bluetoothProvider;
  void _onConnectDeviceHandler(Peripheral peripheral) {
    Timer(
        Duration(seconds: 1),
        () => {
              setState(() {
                _connectedDevices = 1;
                _connectedPeripheral = peripheral;
              })
            });
  }

  void _onDisconnectDeviceHandler() {
    Timer(
        Duration(seconds: 1),
        () => {
              setState(() {
                _connectedDevices = 0;
                _connectedPeripheral = null;
                _temperature = 0;
              })
            });
  }

  void _onTemperatureChange(double temperature) {
    Timer(
        Duration(seconds: 1),
        () => {
              setState(() {
                _temperature = temperature ?? 0;
              })
            });
  }

  void _onScanPeripheralsHandler(List<Peripheral> scannedPeripherals) {
    Timer(
        Duration(seconds: 1),
        () => {
              setState(() {
                _scannedPeripherals = scannedPeripherals;
              })
            });
  }

  void _onPeripheralListClick(Peripheral peripheral) {
    print('connect to ${peripheral.name}');
    bluetoothProvider.connectToPeripheral(peripheral);
  }

  @override
  Widget build(BuildContext context) {
    bluetoothProvider = Provider.of<BluetoothProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Spacer(),
            Text(
              'You have ${_scannedPeripherals?.length ?? 0} scanned devices',
              style: Theme.of(context).textTheme.headline5,
            ),
            Spacer(),
            _connectedDevices > 0
                ? Column(
                    children: <Widget>[
                      Text(
                        '${_connectedPeripheral?.name ?? 'No Device'}',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                      Text(
                        'Device Connected',
                        style: Theme.of(context).textTheme.bodyText2,
                      )
                    ],
                  )
                : PeripheralsList(
                    peripherals: _scannedPeripherals,
                    onClick: _onPeripheralListClick,
                  ),
            Spacer(),
            Text(
              '${_connectedDevices > 0 ? _temperature.toStringAsFixed(1) + 'C' : ''}',
              style: Theme.of(context).textTheme.headline4,
            ),
            Spacer(),
            BlueToothBtnWidget(
              ble: bluetoothProvider,
              onConnectDevice: _onConnectDeviceHandler,
              onTemperatureChange: _onTemperatureChange,
              onDisconnectDevice: _onDisconnectDeviceHandler,
              onScanPeripherals: _onScanPeripheralsHandler,
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
