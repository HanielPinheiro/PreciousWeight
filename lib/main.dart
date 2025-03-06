import 'package:flutter/material.dart';
import 'package:precious_weight/repository/design/theme.dart';
import 'views/login/login.dart';

void main() => runApp(PreciousWeightApp());

class PreciousWeightApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Precious Weight',
      themeMode: ThemeMode.system,
      theme: PreciousWeightTheme.light(),
      darkTheme: PreciousWeightTheme.dark(),
      home: const LoginPage(), // Start with the login page
    );
  }
}