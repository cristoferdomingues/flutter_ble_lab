import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'providers/providers.dart';

class BlueToothBtnWidget extends StatefulWidget {
  final Function onConnectDevice;
  final Function onDisconnectDevice;
  final Function onTemperatureChange;
  final Function onScanPeripherals;
  final BluetoothProvider ble;
  BlueToothBtnWidget(
      {Key key,
      this.onConnectDevice,
      this.onDisconnectDevice,
      this.onTemperatureChange,
      this.onScanPeripherals, this.ble})
      : super(key: key);

  @override
  _BlueToothBtnWidgetState createState() => _BlueToothBtnWidgetState();
}

class _BlueToothBtnWidgetState extends State<BlueToothBtnWidget> {
 
  bool _bleLatestConnectionStatus = false;
  @override
  Widget build(BuildContext context) {
    onConnectionStatusChangeHandler(widget.ble.connected);
    widget.onTemperatureChange(widget.ble.temperature);
    widget.onScanPeripherals(widget.ble.scannedPeripherals);
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Ink(
          decoration: const ShapeDecoration(
              shape: CircleBorder(), color: Colors.lightBlue),
          height: 100,
          child: IconButton(
            icon: Icon(Icons.bluetooth),
            onPressed: () => _onPressedHadler(),
            iconSize: 24.0,
            tooltip: 'Press to find new bluetooth devices',
            color: widget.ble.scanning ? Colors.orange : Colors.white,
          ),
        ),
      ),
    );
  }

  void _onPressedHadler() {
    _bleLatestConnectionStatus == false
        ? widget.ble.scanPeripherals()
        : widget.ble.disconnectFromPeripheral();
  }

  void onConnectionStatusChangeHandler(bool bleCurrentConnStatus) {
    if (bleCurrentConnStatus != _bleLatestConnectionStatus &&
        bleCurrentConnStatus == true) {
      if (widget.ble.connectedPeripheral != null && widget.onConnectDevice != null)
        widget.onConnectDevice(widget.ble.connectedPeripheral);
    } else if (bleCurrentConnStatus != _bleLatestConnectionStatus &&
        bleCurrentConnStatus == false) {
      if (widget.onDisconnectDevice != null) widget.onDisconnectDevice();
    }

    _bleLatestConnectionStatus = bleCurrentConnStatus;
  }
}
