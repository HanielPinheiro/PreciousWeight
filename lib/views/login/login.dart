import 'package:flutter/material.dart';
import '../../repository/design/fonts.dart';
import '../../repository/widgets/menu.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  // final mqtt = new MqttService();
  // final _user_api = new UserApi();

  @override
  void initState() {
    super.initState();
    // mqtt.start();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: ListView(padding: const EdgeInsets.symmetric(horizontal: 8.0), children: <Widget>[
      const SizedBox(height: 80.0),
      Column(
        children: <Widget>[
          Image.asset("assets/imgs/logo.png", fit: BoxFit.fitWidth),
          const SizedBox(height: 16.0),
          RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(text: 'Precious ', style: notosans_50.copyWith(
                  color:Theme.of(context).brightness == Brightness.dark? Colors.white: Theme.of(context).colorScheme.onPrimary
                )),
                TextSpan(text: 'Weight', style: caprasimo_50.copyWith(
                  color:Theme.of(context).colorScheme.onSecondary,
                ))
              ])
          ),
          const SizedBox(height: 120.0),
          TextField(
            controller: _usernameController,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
              labelText: 'Username',
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
              hintText: 'Digite seu usuário',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)),
            ),
          ),
          const SizedBox(height: 12.0),
          TextField(
              controller: _passwordController,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.password, color: Theme.of(context).colorScheme.primary),
                labelText: 'Password',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                focusedBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)),
              ),
              obscureText: true),
          const SizedBox(height: 20.0),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  _usernameController.clear();
                  _passwordController.clear();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                    style: BorderStyle.solid,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                ),
                child: const Text('CANCEL'),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton.icon(
                icon: Icon(Icons.login, color: Colors.black),
                label: Text('ENTRAR', style: headlineSmall.copyWith(color: Colors.black)),
                onPressed: () async {
                  // final token = await _user_api.getToken(_usernameController.text,_passwordController.text);
                  final token = "asd";
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MenuManager()),
                  );
                                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  backgroundColor: Theme.of(context).colorScheme.onSecondary,
                  elevation: 4.0,
                  // side: BorderSide(color: Theme.of(context).colorScheme.onSecondary, width: 1.0, style: BorderStyle.solid,),
                ),
              ),
            ],
          ),
        ],
      ),
    ])));
  }
}


