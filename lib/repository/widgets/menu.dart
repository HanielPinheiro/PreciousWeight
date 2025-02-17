import 'package:flutter/material.dart';
import '../../repository/widgets/elements.dart';
import '../../views/babies/babies.dart';
import '../../views/home/home.dart';
import '../../views/login/login.dart';
import '../../views/logs/logs.dart';
import '../../views/scales/scales.dart';
import '../design/constants.dart';

class MenuManager extends StatefulWidget {
  @override
  _MenuManagerState createState() => _MenuManagerState();
}

class _MenuManagerState extends State<MenuManager> {
  int currentPageIndex = 0; // Index of the selected bottom nav item

  var destinations = const <Widget>[
    NavigationDestination(
      selectedIcon: Icon(Icons.home),
      icon: Icon(Icons.home_outlined),
      label: lbl_home_br,
    ),
    NavigationDestination(
      icon: Badge(child: Icon(Icons.bedroom_baby)),
      label: lbl_babies_br,
    ),
    NavigationDestination(
      icon: Badge(label: Text(''), child: Icon(Icons.scale)),
      label: lbl_scales_br,
    ),
    NavigationDestination(
      icon: Badge(label: Text(''), child: Icon(Icons.note_alt)),
      label: lbl_logs_br,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ElementsOfViews.SimpleAppBar('Olá [Nome Usuario]', 'Logout', Icon(Icons.logout, semanticLabel: 'logout'), () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      }),
      body: <Widget>[HomePage(), BabiesPage(), ScalesPage(), LogsPage()][currentPageIndex],
      bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Colors.amber,
          selectedIndex: currentPageIndex,
          destinations: destinations),
    );
  }
}
