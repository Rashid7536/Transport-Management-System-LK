import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class homeBody extends StatefulWidget {
  const homeBody({super.key});

  @override
  State<homeBody> createState() => _homeBodyState();
}

class _homeBodyState extends State<homeBody> {
  final Fdb = FirebaseDatabase.instance.ref();

  String usersName = 'null';
  String CurrentArea = 'null';
  String CurrentCity = 'null';
  bool isloadingL = false;
  bool isloadingN = false;
  @override
  void initState() {
    super.initState();

    getName();
    getLocation();
  }

  void getName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final emailRet = currentUser!.email;
    dynamic dataRet = await Fdb.child('users').get();
    final JSONData = dataRet.value;
    print(JSONData.toString());
    print('OK 0');
    print(emailRet.toString());
    JSONData.forEach((key, userData) {
      //print('OK 1');
      print(userData.toString());
      if (userData['userName'] == emailRet) {
        setState(() {
          usersName = userData['Fname'];
        });
        print(usersName.toString());
      }
      //print(NameData.toString());
      //print('OK 2');
    });
    print('After: ' + usersName.toString());
    isloadingN = true;
  }

  void getLocation() async {
    Position currentLocation = await _determinePosition();
    print('Loc:' + currentLocation.toString());
    // Get the coordinates
    double latitude = currentLocation.latitude;
    double longitude = currentLocation.longitude;

    // Use the geocoding package to get the address
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude, longitude);
    Placemark place = placemarks[0];
    String? Area = place.street.toString();
    String? City = place.subLocality.toString();
    //String? Street = place.street.toString();
    print('place' + place.toString());
    setState(() {
      CurrentArea = Area;
      CurrentCity = City;
      isloadingL = true;
    });
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //key: UniqueKey(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Container(
                    padding: EdgeInsets.only(left: 20, top: 10),
                    alignment: Alignment.topLeft,
                    child: Text(
                      ' Home',
                      textAlign: TextAlign.left,
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    )),
                Container(
                  height: 200,
                  width: 200,
                  child: CircleAvatar(
                    backgroundImage: AssetImage('assets/userIcon.jpg'),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(top: 8, left: 25, right: 25),
                  child: Card(
                    //shape: CircleBorder(side: BorderSide.none),
                    elevation: 25,
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsets.only(left: 20)),
                        isloadingN
                            ? RichText(
                                text: TextSpan(
                                    text: '\nHello, ' +
                                        usersName.toString() +
                                        '\n',
                                    style: TextStyle(
                                        fontSize: 25, color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: 'Welcome Back,\n\n',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.black),
                                      )
                                    ]),
                              )
                            : CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(10)),
Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20), // Add horizontal padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      isloadingN
                          ? Expanded(
                              child: Card(
                                elevation: 25,
                                color: Colors.white,
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      16), // Add padding inside the card
                                  child: RichText(
                                    text: TextSpan(
                                      text: '\nSystem: \n',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Online\n',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : CircularProgressIndicator(),
                      SizedBox(width: 20), // Add spacing between the cards
                      isloadingL
                          ? Expanded(
                              child: Card(
                                elevation: 25,
                                color: Colors.white,
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      16), // Add padding inside the card
                                  child: RichText(
                                    text: TextSpan(
                                      text:
                                          '\nLocation: ${CurrentArea.toString()}\n',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : CircularProgressIndicator(),
                    ],
                  ),
                ),

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.start,
                //   children: [
                //     Padding(padding: EdgeInsets.only(left: 25)),
                //     Expanded(
                //       child: Card(
                //         //shape: CircleBorder(side: BorderSide.none),
                //         elevation: 25,
                //         color: Colors.white,
                //         child: Row(
                //           children: [
                //             Padding(padding: EdgeInsets.only(left: 25)),
                //             Flexible(
                //               child: isloadingN
                //                   ? Text(
                //                       '\n' +
                //                           'Location: \n' +
                //                           CurrentArea.toString() +
                //                           '\n',
                //                       style: TextStyle(
                //                           fontSize: 20,
                //                           fontWeight: FontWeight.bold),
                //                     )
                //                   : CircularProgressIndicator(),
                //             ),
                //             Padding(padding: EdgeInsets.only(left: 25)),
                //           ],
                //         ),
                //       ),
                //     ),
                //     Expanded(
                //       child: Card(
                //         //shape: CircleBorder(side: BorderSide.none),
                //         elevation: 25,
                //         color: Colors.white,
                //         child: Flexible(
                //           child: Row(
                //             children: [
                //               Padding(padding: EdgeInsets.only(left: 25)),
                //               isloadingN
                //                   ? RichText(
                //                       text: TextSpan(
                //                           text: '\nSystem: \n',
                //                           style: TextStyle(
                //                               fontSize: 18,
                //                               fontWeight: FontWeight.bold,
                //                               color: Colors.black),
                //                           children: [
                //                             TextSpan(
                //                               text: 'Online\n',
                //                               style: TextStyle(
                //                                   fontSize: 18,
                //                                   fontWeight: FontWeight.bold,
                //                                   color: Colors.green),
                //                             )
                //                           ]),
                //                     )
                //                   : CircularProgressIndicator(),
                //               Padding(padding: EdgeInsets.only(left: 25)),
                //             ],
                //           ),
                //         ),
                //       ),
                //     ),
                //     Padding(padding: EdgeInsets.only(right: 25))
                //   ],
                // ),
                Padding(padding: EdgeInsets.all(10)),
                Container(
                  padding: EdgeInsets.only(top: 8, left: 25, right: 25),
                  child: Card(
                    //shape: CircleBorder(side: BorderSide.none),
                    elevation: 25,
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsets.only(left: 20)),
                        isloadingN
                            ? RichText(
                                text: TextSpan(
                                  text: '\nCity: ' +
                                      CurrentCity.toString() +
                                      '\n',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            : CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
