import 'package:flutter/material.dart';
import '../../repository/widgets/menu.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: <Widget>[
            const SizedBox(height: 80.0),
            Column(children: <Widget>[
              Icon(
                Icons.cabin,
                size: 100,
                semanticLabel: 'logo',
              ),
              const SizedBox(height: 16.0),
              Text('GOMA', style: Theme.of(context).textTheme.headlineSmall)
            ]),
            const SizedBox(height: 120.0),
            TextField(controller: _usernameController, decoration: const InputDecoration(prefixIcon: Icon(Icons.person), labelText: 'Username')),
            const SizedBox(height: 12.0),
            TextField(controller: _passwordController, decoration: const InputDecoration(prefixIcon: Icon(Icons.password), labelText: 'Password'), obscureText: true),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    _usernameController.clear();
                    _passwordController.clear();
                  },
                  style: TextButton.styleFrom(backgroundColor: Theme.of(context).scaffoldBackgroundColor, foregroundColor: Theme.of(context).appBarTheme.foregroundColor),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.login,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  label: const Text('LOGIN'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MenuManager()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
                    backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                    elevation: 10.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
