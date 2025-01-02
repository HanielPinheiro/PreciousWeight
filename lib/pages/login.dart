import 'package:app_files/structures/view.dart';
import 'package:flutter/material.dart';

import '../structures/definitions.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // var globalItens = context.watch<GlobalItens>();

    Widget? top_itens = Column(children: [Image.asset('assets/imgs/logotipo.png')]);

    Widget? down_itens = Card(
        color: Definitions.blue,
        elevation: 0, // Removes shadow
        child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              BasicStructureOfViews.RoundedInput('Login'),
              SizedBox(height: 14),
              BasicStructureOfViews.RoundedInput('Senha'),

              // Botão Recuperar Senha ====================
              BasicStructureOfViews.AlignedTextButton(
                  'Recuperar Senha', Definitions.amaranth_20_white, Alignment.centerRight, () {}),
              SizedBox(height: 25),

              // Botão fazer login ===================
              BasicStructureOfViews.RoundedElevatedButton('LOGAR', Definitions.strong_orange, Definitions.baloo2_24_white, () {}),

              // Botão criar uma conta ====================
              SizedBox(height: 90),
              BasicStructureOfViews.AlignedTextButton(
                  'Criar uma conta', Definitions.amaranth_24_white, Alignment.topCenter, () {})
            ])));

    return BasicStructureOfViews.Login(top_itens, down_itens);
  }
}
