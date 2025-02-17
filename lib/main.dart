import 'package:flutter/material.dart';
import 'views/login/login.dart';

void main() => runApp(PreciousWeightApp());

class PreciousWeightApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Precious Weight',
      themeMode: ThemeMode.system,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const LoginPage(), // Start with the login page
    );
  }
}