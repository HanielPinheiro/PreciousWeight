import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repository/providers/baby_provider.dart';
import 'repository/design/theme.dart';
import 'views/login/login.dart';

void main() => runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BabyProvider()),
      ],
      child:PreciousWeightApp()
    ),
);

class PreciousWeightApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Precious Weight',
      themeMode: ThemeMode.system,
      theme: PreciousWeightTheme.light(),
      darkTheme: PreciousWeightTheme.dark(),
      home: const LoginPage(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/imgs/logotipo.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}