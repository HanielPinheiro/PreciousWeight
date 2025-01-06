import 'package:flutter/material.dart';
import '../structures//view.dart';
import '../structures/definitions.dart';
import '../structures/elements.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // var globalItens = context.watch<GlobalItens>();

    Widget? topContent = Column(children: [Image.asset('assets/imgs/logotipo.png')]);

    Widget? downContent = Card(
        color: Definitions.blue,
        elevation: 0, // Removes shadow
        child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ElementsOfViews.RoundedInput('Login'),
              SizedBox(height: 14),
              ElementsOfViews.RoundedInput('Senha'),

              // Botão Recuperar Senha ====================
              ElementsOfViews.AlignedTextButton(
                  'Recuperar Senha', Definitions.amaranth_20_white, Alignment.centerRight, () {}),
              SizedBox(height: 25),

              // Botão fazer login ===================
              ElementsOfViews.RoundedElevatedButton('LOGAR', Definitions.strong_orange, Definitions.baloo2_24_white, () {}),

              // Botão criar uma conta ====================
              SizedBox(height: 90),
              ElementsOfViews.AlignedTextButton(
                  'Criar uma conta', Definitions.amaranth_24_white, Alignment.topCenter, () {})
            ])));

    return BasicStructureOfViews.Login(topContent, downContent);
  }
}
