import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';

class PeripheralsList extends StatelessWidget {
  final List<Peripheral> peripherals;
  final Function onClick;
  const PeripheralsList({Key key, this.peripherals, this.onClick})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: !peripherals.isEmpty ? peripherals?.length : 0,
      shrinkWrap: true,
      itemBuilder: (context, index) => ListTile(
        leading: Icon(Icons.bluetooth),
        title: Text(peripherals[index].name),
        subtitle: Text(peripherals[index].identifier),
        onTap: () => onClick(peripherals[index]),
      ),
    );
  }
}
