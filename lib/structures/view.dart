import 'package:app_files/structures/definitions.dart';
import 'package:flutter/material.dart';

class BasicStructureOfViews {
  static Widget Login(Widget? childrens_top, Widget? childrens_down) {
    return Column(children: <Widget>[
      Expanded(
        flex: 4, // 40%
        child: Container(
            color: Definitions.white,
            child: Padding(
                /*Aqui, padding 50 em top para dar espaço no topo e não prejudicar logotipo*/
                padding: Definitions.top_50,
                child: Container(color: Definitions.white, child: childrens_top))),
      ),
      Expanded(
          flex: 6, // 60%
          child: Container(
              color: Definitions.blue,
              child: Padding(
                /*Aqui, padding 50 em top para dar espaço no topo e não prejudicar logotipo*/
                padding: Definitions.all,
                child: Container(color: Definitions.blue, child: childrens_down),
              )))
    ]); //,
  }

  static RoundedInput(String text) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text, style: Definitions.amaranth_20_white),
      SizedBox(height: 5),
      TextFormField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Definitions.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    ]);
  }

  static AlignedTextButton(String text, TextStyle style, Alignment align, VoidCallback? action) {
    return Align(
        alignment: align, //Alignment.centerRight,
        child: TextButton(
            onPressed: action, //() { },
            child: Text(text, style: style) //Definitions.amaranth_20_white),
            ));
  }

  static RoundedElevatedButton(String text, Color color, TextStyle style, VoidCallback? action) {
    return ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(text, style: style));
  }
}
