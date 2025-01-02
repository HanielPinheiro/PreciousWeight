import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/login.dart';

void main() {
  runApp(Orchestror());
}

class Orchestror extends StatelessWidget {
  const Orchestror({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GlobalItens(),
      child: MaterialApp(
        title: 'Precious Weight',
        theme: ThemeData(useMaterial3: true),
        home: LoginPage(),
      ),
    );
  }
}

class GlobalItens extends ChangeNotifier {/* To be used*/}