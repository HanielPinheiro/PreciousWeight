import 'package:flutter/material.dart';
import 'definitions.dart';

class BasicStructureOfViews {
  static Login(Widget? childrensTop, Widget? childrensDown) {
    return Column(children: <Widget>[
      Expanded(
        flex: 4, // 40%
        child: Container(
            color: Definitions.white,
            child: Padding(
                /*Aqui, padding 50 em top para dar espaço no topo e não prejudicar logotipo*/
                padding: Definitions.top_50,
                child: Container(color: Definitions.white, child: childrensTop))),
      ),
      Expanded(
          flex: 6, // 60%
          child: Container(
              color: Definitions.blue,
              child: Padding(
                /*Aqui, padding 50 em top para dar espaço no topo e não prejudicar logotipo*/
                padding: Definitions.all,
                child: Container(color: Definitions.blue, child: childrensDown),
              )))
    ]); //,
  }

  static Home(Widget? childrensTop, Widget? childrensMid, Widget? childrensDown) {
    return Column(children: <Widget>[
      Expanded(
        flex: 10, // 10%
        child: Container(
            color: Definitions.white,
            child: Padding(padding: Definitions.top_30, child: Container(color: Definitions.white, child: childrensTop))),
      ),
      Expanded(
        flex: 75, // 75%
        child: Container(
            color: Definitions.blue,
            child: Padding(padding: Definitions.top_40, child: Container(color: Definitions.blue, child: childrensMid))),
      ),
      Expanded(
          flex: 15, // 15%
          child: Container(
              color: Definitions.strong_orange,
              child: Padding(
                padding: Definitions.all,
                child: Container(color: Definitions.strong_orange, child: childrensDown),
              )))
    ]); //,
  }
}
