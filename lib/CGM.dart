import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:blemulator/blemulator.dart';

// Simplified simulation of Texas Instruments CC2541 SensorTag
// http://processors.wiki.ti.com/images/a/a8/BLE_SensorTag_GATT_Server.pdf
class CGM extends SimulatedPeripheral {
  CGM(
      {String id = "5B:88:9C:36:DE:66",
      String name = "Continuos Glucometer Monitor",
      String localName = "CGM - RiseCx"})
      : super(
            name: name,
            id: id,
            advertisementInterval: Duration(milliseconds: 800),
            services: [
              //IR Temperature service implemented according to docs
              CGMService(
                  uuid: "b77c5c22-b4ed-11ea-b3de-0242ac130004",
                  isAdvertised: true,
                  convenienceName: "Glucometer Monitor Serivce"),
              //Simplified accelerometer service
              SimulatedService(
                  uuid: "cd50b8cc-b4ed-11ea-b3de-0242ac130004",
                  isAdvertised: true,
                  characteristics: [
                    SimulatedCharacteristic(
                        uuid: "d4859cca-b4ed-11ea-b3de-0242ac130004",
                        value: Uint8List.fromList([0, 0]),
                        convenienceName: "Accelerometer Config",
                        isWritableWithResponse: false,
                        isWritableWithoutResponse: false,
                        isNotifiable: true),
                    SimulatedCharacteristic(
                        uuid: "de712c86-b4ed-11ea-b3de-0242ac130004",
                        value: Uint8List.fromList([2]),
                        convenienceName: "Accelerometer Config"),
                    SimulatedCharacteristic(
                        uuid: "e5bb0ff2-b4ed-11ea-b3de-0242ac130004",
                        value: Uint8List.fromList([30]),
                        convenienceName: "Accelerometer Period"),
                  ],
                  convenienceName: "Accelerometer Service")
            ]) {
    scanInfo.localName = localName;
  }

  @override
  Future<bool> onConnectRequest() async {
    await Future.delayed(Duration(milliseconds: 200));
    return super.onConnectRequest();
  }

  @override
  Future<void> onDiscoveryRequest() async {
    await Future.delayed(Duration(milliseconds: 500));
    return super.onDiscoveryRequest();
  }
}

class CGMService extends SimulatedService {
  static const String _cgmDataUuid =
      "19e93ca4-b4ee-11ea-b3de-0242ac130004";
  static const String _cgmConfigUuid =
      "19e93ef2-b4ee-11ea-b3de-0242ac130004";
  static const String _cgmPeriodUuid =
      "19e9400a-b4ee-11ea-b3de-0242ac130004";

  bool _readingTemperature = false;

  CGMService(
      {@required String uuid,
      @required bool isAdvertised,
      String convenienceName})
      : super(
            uuid: uuid,
            isAdvertised: isAdvertised,
            characteristics: [
              SimulatedCharacteristic(
                uuid: _cgmDataUuid,
                value: Uint8List.fromList([0, 0, 0, 0]),
                convenienceName: "CGM Data",
                isNotifiable: true,
                descriptors: [
                  SimulatedDescriptor(
                    uuid: "19e940fa-b4ee-11ea-b3de-0242ac130004",
                    value: Uint8List.fromList([0]),
                    convenienceName: "Client characteristic configuration",
                  ),
                  SimulatedDescriptor(
                    uuid: "19e94280-b4ee-11ea-b3de-0242ac130004",
                    value: Uint8List.fromList([0]),
                    writable: false,
                    convenienceName: "Characteristic user description",
                  ),
                ],
              ),
              BooleanCharacteristic(
                uuid: _cgmConfigUuid,
                initialValue: false,
                convenienceName: "CGM  Alarm Config",
              ),
              SimulatedCharacteristic(
                  uuid: _cgmPeriodUuid,
                  value: Uint8List.fromList([50]),
                  convenienceName: "CGM  Period"),
            ],
            convenienceName: convenienceName) {
    characteristicByUuid(_cgmConfigUuid).monitor().listen((value) {
      _readingTemperature = value[0] == 1;

      if (_readingTemperature) {
        SimulatedCharacteristic temperatureDataCharacteristic =
            characteristicByUuid(_cgmDataUuid);

        temperatureDataCharacteristic.write(
          Uint8List.fromList([0, 0, 100, Random().nextInt(255)]),
          sendNotification: false,
        );
      }
    });

    _emitMgdL();
  }

  void _emitMgdL() async {
    while (true) {
      Uint8List delayBytes =
          await characteristicByUuid(_cgmPeriodUuid).read();
      int delay = delayBytes[0] * 100;
      await Future.delayed(Duration(milliseconds: delay));

      SimulatedCharacteristic temperatureDataCharacteristic =
          characteristicByUuid(_cgmDataUuid);

      if (temperatureDataCharacteristic.isNotifying) {
        if (_readingTemperature) {
          temperatureDataCharacteristic
              .write(Uint8List.fromList([0, 0, 100, Random().nextInt(255)]));
        } else {
          temperatureDataCharacteristic
              .write(Uint8List.fromList([0, 0, 100, Random().nextInt(255)]));
        }
      }
    }
  }
}

class BooleanCharacteristic extends SimulatedCharacteristic {
  BooleanCharacteristic(
      {@required uuid, @required bool initialValue, String convenienceName})
      : super(
            uuid: uuid,
            value: Uint8List.fromList([initialValue ? 1 : 0]),
            convenienceName: convenienceName);

  @override
  Future<void> write(Uint8List value, {bool sendNotification = true}) {
    int valueAsInt = value[0];
    if (valueAsInt != 0 && valueAsInt != 1) {
      return Future.error(SimulatedBleError(
          BleErrorCode.CharacteristicWriteFailed, "Unsupported value"));
    } else {
      return super.write(value); //this propagates value through the blemulator,
      // allowing you to react to changes done to this characteristic
    }
  }
}
