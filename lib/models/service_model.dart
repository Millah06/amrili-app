import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ServiceModel {
  bool ? isNew;
  String name;
  FaIconData icon;
  Function() function;

  ServiceModel({required this.name, required this.icon, required this.function, this.isNew});
}