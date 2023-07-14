import 'package:flutter/material.dart';

class Constants extends InheritedWidget {
  static Constants? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Constants>();

  const Constants({required Widget child, Key? key}): super(key: key, child: child);

  final String successMessage = 'Some message';
  final String DEFAULT_THE_NODE_IP = "192.168.4.1"; // // "192.168.1.199";
  final String DEFAULT_THE_NODE_DNS = "thenode"; // thenode[macaddress] example is thenode84:CC:A8:88:6E:07

  static const MODE_BURST = "burst";
  static const MODE_POLLING = "polling";
  static const MODE_SETUP = "setup";
  static const MODE_REQUEST = "request";
  static const MODE_OFFLINE = "offline";

  // Operation Mode
  static const MODE_AUTO = 'auto';
  static const MODE_MANUAL = 'manual';

  static const SWITCH_ON = 'on';
  static const SWITCH_OFF = 'off';

  static const MQTT_COMMAND_SWITCH_OFF = 'manual_0_';
  static const MQTT_COMMAND_SWITCH_ON = 'manual_1_';

  static const INTERVAL_2_MIN_IN_SECOND = 120;
  static const INTERVAL_3_MIN_IN_SECOND = 180;

  static const INTERVAL_SECOND_10 = 10000;
  static const INTERVAL_SECOND_30 = 30000;
  static const INTERVAL_MINUTE_1 = 60000;
  static const INTERVAL_MINUTE_2 = 120000;
  static const INTERVAL_MINUTE_3 = 180000;
  static const INTERVAL_MINUTE_4 = 240000;
  static const INTERVAL_MINUTE_5 = 300000;
  static const INTERVAL_MINUTE_10 = 600000;
  static const INTERVAL_MINUTE_15 = 900000;
  static const INTERVAL_MINUTE_20 = 1200000;
  static const INTERVAL_MINUTE_30 = 1800000;
  static const INTERVAL_HOUR_1 = 3600000;
  static const INTERVAL_HOUR_2 = 7200000;
  static const INTERVAL_HOUR_3 = 10800000;
  static const INTERVAL_HOUR_4 = 14400000;
  static const INTERVAL_HOUR_5 = 18000000;
  static const INTERVAL_HOUR_6 = 21600000;
  static const INTERVAL_HOUR_12 = 43200000;
  static const INTERVAL_HOUR_24 = 86400000;

  static const TEMP_LOWER = 1;
  static const TEMP_HIGHER = 2;
  static const HUMID_LOWER = 3;
  static const HUMID_HIGHER = 4;
  static const TANK_FILLED_LEVEL_LOWER = 5;
  static const TANK_FILLED_LEVEL_HIGHER = 6;

  // TOF10120(Water Leveling Sensor) Constants
  /**
   * Tank Types
   */
  static const TANK_TYPE_SIMPLE = 'Simple';
  static const TANK_TYPE_HORIZONTAL_CYLINDER = 'Horizontal Cylinder';
  static const TANK_TYPE_VERTICAL_CYLINDER = 'Vertical Cylinder';
  static const TANK_TYPE_RECTANGLE = 'Rectangle';
  static const TANK_TYPE_HORIZONTAL_OVAL = 'Horizontal Oval';
  static const TANK_TYPE_VERTICAL_OVAL = 'Vertical Oval';
  static const TANK_TYPE_HORIZONTAL_CAPSULE = 'Horizontal Capsule';
  static const TANK_TYPE_VERTICAL_CAPSULE = 'Vertical Capsule';
  static const TANK_TYPE_HORIZONTAL_2_1_ELLIPTICAL = 'Horizontal 2:1 Elliptical';
  static const TANK_TYPE_HORIZONTAL_DISH_ENDS = 'Horizontal Dish Ends';
  static const TANK_TYPE_HORIZONTAL_ELLIPSE = 'Horizontal Ellipse';

  // Filled Tank Percentage Number
  static const FILLED_PERCENTAGE_0 = '0';
  static const FILLED_PERCENTAGE_25 = '25';
  static const FILLED_PERCENTAGE_50 = '50';
  static const FILLED_PERCENTAGE_75 = '75';
  static const FILLED_PERCENTAGE_100 = '100';

  // Console Type
  static const CONSOLE_TYPE_DISTANCE_SENSOR = 'Distance Sensor';
  static const CONSOLE_TYPE_PUMP_RELAY = 'Pump Relay';

  static const CONSOLE_STATUS_LOST_CONNECT = 'Lost connect!';
  static const CONSOLE_STATUS_LOST_CONNECT_LOWER_CASE = 'lost connect!';

  // Dimension Types
  static const DIMENSION_TYPE_OFFSET = 'Offset (o)';
  static const DIMENSION_TYPE_CAPACITY = 'Capacity (c)';
  static const DIMENSION_TYPE_LENGTH = 'Length (l)';
  static const DIMENSION_TYPE_DIAMETER = 'Diameter (d)';
  static const DIMENSION_TYPE_HEIGHT = 'Height (h)';
  static const DIMENSION_TYPE_WIDTH = 'Width (w)';
  static const DIMENSION_TYPE_SIDE_LENGTH = 'Side Length (a)';



  // Tank Types
  static const Map<String, Map<String, String>> gTankTypesMap = {
    TANK_TYPE_SIMPLE: {DIMENSION_TYPE_HEIGHT: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_CAPACITY: VOLUME_TYPE_LITERS},
    TANK_TYPE_HORIZONTAL_CYLINDER: {DIMENSION_TYPE_LENGTH: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_DIAMETER: UNIT_TYPE_CENTIMETRE},
    TANK_TYPE_VERTICAL_CYLINDER: {DIMENSION_TYPE_HEIGHT: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_DIAMETER: UNIT_TYPE_CENTIMETRE},
    TANK_TYPE_RECTANGLE: {DIMENSION_TYPE_HEIGHT: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_WIDTH: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_LENGTH: UNIT_TYPE_CENTIMETRE},
    TANK_TYPE_HORIZONTAL_OVAL: {DIMENSION_TYPE_HEIGHT: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_WIDTH: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_LENGTH: UNIT_TYPE_CENTIMETRE},
    TANK_TYPE_VERTICAL_OVAL: {DIMENSION_TYPE_HEIGHT: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_WIDTH: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_LENGTH: UNIT_TYPE_CENTIMETRE},
    TANK_TYPE_HORIZONTAL_CAPSULE: {DIMENSION_TYPE_SIDE_LENGTH: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_DIAMETER: UNIT_TYPE_CENTIMETRE},
    TANK_TYPE_VERTICAL_CAPSULE: {DIMENSION_TYPE_SIDE_LENGTH: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_DIAMETER: UNIT_TYPE_CENTIMETRE},
    TANK_TYPE_HORIZONTAL_2_1_ELLIPTICAL: {DIMENSION_TYPE_SIDE_LENGTH: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_DIAMETER: UNIT_TYPE_CENTIMETRE},
    TANK_TYPE_HORIZONTAL_DISH_ENDS: {DIMENSION_TYPE_SIDE_LENGTH: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_DIAMETER: UNIT_TYPE_CENTIMETRE},
    TANK_TYPE_HORIZONTAL_ELLIPSE: {DIMENSION_TYPE_HEIGHT: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_WIDTH: UNIT_TYPE_CENTIMETRE, DIMENSION_TYPE_LENGTH: UNIT_TYPE_CENTIMETRE},
  };

  static const Map<String, String> gTankImagesMap = {
    TANK_TYPE_SIMPLE: 'images/tanks/base_simple.jpg',
    TANK_TYPE_HORIZONTAL_CYLINDER: 'images/tanks/base_horizontal_cylinder.jpg',
    TANK_TYPE_VERTICAL_CYLINDER: 'images/tanks/base_vertical_cylinder.jpg',
    TANK_TYPE_RECTANGLE: 'images/tanks/base_rectangle.jpg',
    TANK_TYPE_HORIZONTAL_OVAL: 'images/tanks/base_horizontal_oval.jpg',
    TANK_TYPE_VERTICAL_OVAL: 'images/tanks/base_vertical_oval.jpg',
    TANK_TYPE_HORIZONTAL_CAPSULE: 'images/tanks/base_horizontal_capsule.jpg',
    TANK_TYPE_VERTICAL_CAPSULE: 'images/tanks/base_vertical_capsule.jpg',
    TANK_TYPE_HORIZONTAL_2_1_ELLIPTICAL: 'images/tanks/base_horizontal_2_1_elliptical.jpg',
    TANK_TYPE_HORIZONTAL_DISH_ENDS: 'images/tanks/base_horizontal_dish_ends.jpg',
    TANK_TYPE_HORIZONTAL_ELLIPSE: 'images/tanks/base_horizontal_ellipse.jpg',
  };

  // Tank Types
  static const Map<String, Map<String, String>> gFilledTankPercentageImagesMap = {
    TANK_TYPE_SIMPLE: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
    TANK_TYPE_HORIZONTAL_CYLINDER: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
    TANK_TYPE_VERTICAL_CYLINDER: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
    TANK_TYPE_RECTANGLE: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
    TANK_TYPE_HORIZONTAL_OVAL: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
    TANK_TYPE_VERTICAL_OVAL: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
    TANK_TYPE_HORIZONTAL_CAPSULE: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
    TANK_TYPE_VERTICAL_CAPSULE: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
    TANK_TYPE_HORIZONTAL_2_1_ELLIPTICAL: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
    TANK_TYPE_HORIZONTAL_DISH_ENDS: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
    TANK_TYPE_HORIZONTAL_ELLIPSE: {
      FILLED_PERCENTAGE_0: 'images/tanks/simple_tank_type_0.png',
      FILLED_PERCENTAGE_25: 'images/tanks/simple_tank_type_25.png',
      FILLED_PERCENTAGE_50: 'images/tanks/simple_tank_type_50.png',
      FILLED_PERCENTAGE_75: 'images/tanks/simple_tank_type_75.png',
      FILLED_PERCENTAGE_100: 'images/tanks/simple_tank_type_100.png'},
  };

  /**
   * Length unit types
   */
  static const UNIT_TYPE_INCH = 'in';
  static const UNIT_TYPE_FOOT = 'ft';
  static const UNIT_TYPE_MILLIMETRE = 'mm';
  static const UNIT_TYPE_CENTIMETRE = 'cm';
  static const UNIT_TYPE_METRE = 'm';

  static const VOLUME_TYPE_US_GALLONS = 'U.S. Gallons';
  static const VOLUME_TYPE_IMP_GALLONS = 'Imp. Gallons';
  static const VOLUME_TYPE_LITERS = 'Liters';
  static const VOLUME_TYPE_CUBIC_METERS = 'Cubic Meters';
  static const VOLUME_TYPE_CUBIC_FEET = 'Cubic Feet';

  static double pie=3.14285714286;

  static List<String> pickerHTValues = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
    '24',
    '25',
    '26',
    '27',
    '28',
    '29',
    '30',
    '31',
    '32',
    '33',
    '34',
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
    '45',
    '46',
    '47',
    '48',
    '49',
    '50',
    '51',
    '52',
    '53',
    '54',
    '55',
    '56',
    '57',
    '58',
    '59',
    '60',
    '61',
    '62',
    '63',
    '64',
    '65',
    '66',
    '67',
    '68',
    '69',
    '70',
    '71',
    '72',
    '73',
    '74',
    '75',
    '76',
    '77',
    '78',
    '79',
    '80',
    '81',
    '82',
    '83',
    '84',
    '85',
    '86',
    '87',
    '88',
    '89',
    '90',
    '91',
    '92',
    '93',
    '94',
    '95',
    '96',
    '97',
    '98',
    '99',
    '100',
  ];

  static List<String> pickerWaterLevelValues = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
    '24',
    '25',
    '26',
    '27',
    '28',
    '29',
    '30',
    '31',
    '32',
    '33',
    '34',
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
    '45',
    '46',
    '47',
    '48',
    '49',
    '50',
    '51',
    '52',
    '53',
    '54',
    '55',
    '56',
    '57',
    '58',
    '59',
    '60',
    '61',
    '62',
    '63',
    '64',
    '65',
    '66',
    '67',
    '68',
    '69',
    '70',
    '71',
    '72',
    '73',
    '74',
    '75',
    '76',
    '77',
    '78',
    '79',
    '80',
    '81',
    '82',
    '83',
    '84',
    '85',
    '86',
    '87',
    '88',
    '89',
    '90',
    '91',
    '92',
    '93',
    '94',
    '95',
    '96',
    '97',
    '98',
    '99',
    '100',
    '101',
    '102',
    '103',
    '104',
    '105',
    '106',
    '107',
    '108',
    '109',
    '110',
    '111',
    '112',
    '113',
    '114',
    '115',
    '116',
    '117',
    '118',
    '119',
    '120',
    '121',
    '122',
    '123',
    '124',
    '125',
    '126',
    '127',
    '128',
    '129',
    '130',
    '131',
    '132',
    '133',
    '134',
    '135',
    '136',
    '137',
    '138',
    '139',
    '140',
    '141',
    '142',
    '143',
    '144',
    '145',
    '146',
    '147',
    '148',
    '149',
    '150',
    '151',
    '152',
    '153',
    '154',
    '155',
    '156',
    '157',
    '158',
    '159',
    '160',
    '161',
    '162',
    '163',
    '164',
    '165',
    '166',
    '167',
    '168',
    '169',
    '170',
    '171',
    '172',
    '173',
    '174',
    '175',
    '176',
    '177',
    '178',
    '179',
    '180',
    '181',
    '182',
    '183',
    '184',
    '185',
    '186',
    '187',
    '188',
    '189',
    '190',
    '191',
    '192',
    '193',
    '194',
    '195',
    '196',
    '197',
    '198',
    '199',
    '200',
    '201',
    '202',
    '203',
    '204',
    '205',
    '206',
    '207',
    '208',
    '209',
    '210',
    '211',
    '212',
    '213',
    '214',
    '215',
    '216',
    '217',
    '218',
    '219',
    '220',
    '221',
    '222',
    '223',
    '224',
    '225',
    '226',
    '227',
    '228',
    '229',
    '230',
    '231',
    '232',
    '233',
    '234',
    '235',
    '236',
    '237',
    '238',
    '239',
    '240',
    '241',
    '242',
    '243',
    '244',
    '245',
    '246',
    '247',
    '248',
    '249',
    '250',
    '251',
    '252',
    '253',
    '254',
    '255',
    '256',
    '257',
    '258',
    '259',
    '260',
    '261',
    '262',
    '263',
    '264',
    '265',
    '266',
    '267',
    '268',
    '269',
    '270',
    '271',
    '272',
    '273',
    '274',
    '275',
    '276',
    '277',
    '278',
    '279',
    '280',
    '281',
    '282',
    '283',
    '284',
    '285',
    '286',
    '287',
    '288',
    '289',
    '290',
    '291',
    '292',
    '293',
    '294',
    '295',
    '296',
    '297',
    '298',
    '299',
    '300',
  ];

  static List<String> pickerOperationPeriodValues = [
    '30 min',
    '1 hour',
    '2 hours',
    '3 hours',
    '4 hours',
    '5 hours',
    '6 hours',
    '12 hours',
    '24 hours',
  ];

  // static const xx = TextStyle(
  //   color: Colors.white,
  //   fontFamily: 'Kanit',
  //   fontWeight: FontWeight.w300,
  //   fontSize: 12.0,
  // );
  @override
  bool updateShouldNotify(Constants oldWidget) => false;
}