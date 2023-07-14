// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iot_theapp_web/pages/device/model/operation_unit.dart';
import 'package:provider/provider.dart';

/// Mix-in [DiagnosticableTreeMixin] to have access to [debugFillProperties] for the devtool
// ignore: prefer_mixin
class TempOperationUnitList with ChangeNotifier, DiagnosticableTreeMixin {
  int _count = 0;
  List<OperationUnit> _tempOperationUnitLists = [];

  int get count => _count;
  List<OperationUnit> get tempOperationUnitLists => _tempOperationUnitLists;

  void increment() {
    _count++;
    notifyListeners();
  }

  void updateSensor(int index, String sensor) {
    _tempOperationUnitLists[index].sensor = sensor;
    notifyListeners();
  }

  void copy(List<OperationUnit> srcList) {
    _tempOperationUnitLists.clear();

    srcList.forEach((values) {
      _tempOperationUnitLists.add(OperationUnit(
        id: values.id ?? '',
        uid: values.uid ?? '',
        index: int.parse('${values.index ?? "0"}'),
        name: values.name ?? '',
        status: values.status ?? '',
        user: values.user ?? '',
        sensor: values.sensor ?? '',
        updatedWhen: values.updatedWhen ?? '2022-10-11 14:43:00',
      ));
    });
    notifyListeners();
  }

  /// Makes `TempOperationUnitList` readable inside the devtools by listing all of its properties
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', count));
    properties.add(IntProperty('tempOperationUnitLists', tempOperationUnitLists.length));
  }
}