library ftiotsystem.globals;

import 'dart:ffi';

import 'package:intl/intl.dart';

String g_internet_ssid = "";
String g_internet_password = "";

String g_device_name = "";
String g_user_uid = "cray"; // test user uid, it will use to create root node in firebase real time database

String g_appName = '';
String g_packageName = '';
String g_version = '';
String g_buildNumber = '';
String g_mobileServer = '';

String formatNumber(double n) {
  var formatter = NumberFormat('#,##,000');
  if(n < 1000) {
    return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 1);
  } else {
    return formatter.format(double.parse(n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 1)));
  }


}

// double checkDouble(dynamic value) {
//   if (value is String) {
//     return double.parse(value);
//   } else {
//     return value.to;
//   }
// }

double parseDouble(dynamic dAmount){
  double returnAmount = 0.00;
  String strAmount;

  try {

    if (dAmount == null || dAmount == 0) return 0.0;

    strAmount = dAmount.toString();

    if (strAmount.contains('.')) {
      returnAmount = double.parse(strAmount);
    } else { // Didn't need else since the input was either 0, an integer or a double
      if (dAmount is int) return dAmount.toDouble();
    }
  } catch (e) {
    return 0.000;
  }

  return returnAmount;
}

String getTimeCard(String when) {
  try {
    final dash = when.substring(4, 5);
    if (dash == '-') {
      return DateFormat('h:mm a').format(DateTime.parse(when));
    } else {
      return 'h:mm a';
    }
  } catch (e) {
    return 'h:mm a';
  }
}

String getDateCard(String when) {
  try {
    final dash = when.substring(4, 5);
    if (dash == '-') {
      return DateFormat('EEE dd, MMM yyyy').format(DateTime.parse(when));
    } else {
      return 'EEE dd, MMM yyyy';
    }
  } catch (e) {
    return 'EEE dd, MMM yyyy';
  }
}
