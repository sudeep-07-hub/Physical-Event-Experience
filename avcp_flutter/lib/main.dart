/// AVCP Glanceable UI — entry point.
library;

import 'package:flutter/material.dart';

import 'widgets/app/avenu_control_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // In production: await Firebase.initializeApp();
  runApp(const AvenuControlApp());
}
