import 'package:flutter/material.dart';
import 'package:leaflet_test/pages/flutterMap_pck.dart';
import 'package:leaflet_test/pages/homebody.dart';


class reportPage extends StatefulWidget {
  const reportPage({super.key});

  @override
  State<reportPage> createState() => _reportPageState();
}

int stateNavChange = 0;
dynamic List = [
  homeBody(),
  flutterMap_pack() //mapBody('Init', 6.914667, 79.972941)
  ];
//   ,
//   SearchBody()
// ];

class _reportPageState extends State<reportPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //floatingActionButton: FloatingActionButton(onPressed: () {}),
        bottomNavigationBar: NavigationBar(
            //backgroundColor: Colors.,
            elevation: 8,
            onDestinationSelected: (value) {
              setState(
                () {
                  stateNavChange = value;
                },
              );
            },
            selectedIndex: stateNavChange,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.map),
                label: 'Route',
              ),
              // NavigationDestination(
              //   icon: Icon(Icons.search),
              //   label: 'Search',
              // ),
            ]),
        //body: List[stateNavChange],
        body: AnimatedSwitcher(
          duration: Duration(milliseconds: 250),
          child: List[stateNavChange],
        ));
  }
}
