import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'providers/providers.dart';

class BlueToothBtnWidget extends StatefulWidget {
  final Function onConnectDevice;
  final Function onDisconnectDevice;
  final Function onTemperatureChange;
  BlueToothBtnWidget(
      {Key key,
      this.onConnectDevice,
      this.onDisconnectDevice,
      this.onTemperatureChange})
      : super(key: key);

  @override
  _BlueToothBtnWidgetState createState() => _BlueToothBtnWidgetState();
}

class _BlueToothBtnWidgetState extends State<BlueToothBtnWidget> {
  var ble;
  bool _bleLatestConnectionStatus = false;
  @override
  Widget build(BuildContext context) {
    ble = Provider.of<BluetoothProvider>(context);
    onConnectionStatusChangeHandler(ble.connected);
    widget.onTemperatureChange(ble.temperature);
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
            color: ble.scanning ? Colors.orange : Colors.white,
          ),
        ),
      ),
    );
  }

  void _onPressedHadler() {
    _bleLatestConnectionStatus == false ? ble.searchForDevices() : ble.disconnectFromPeripheral();
  }

  void onConnectionStatusChangeHandler(bool bleCurrentConnStatus) {
    if (bleCurrentConnStatus != _bleLatestConnectionStatus &&
        bleCurrentConnStatus == true) {
      if (ble.peripheral != null && widget.onConnectDevice != null)
        widget.onConnectDevice(ble.peripheral);
    } else if (bleCurrentConnStatus != _bleLatestConnectionStatus &&
        bleCurrentConnStatus == false) {
      if (widget.onDisconnectDevice != null) widget.onDisconnectDevice();
    }

    _bleLatestConnectionStatus = bleCurrentConnStatus;
  }
}
