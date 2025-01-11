import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database.dart';

class flutterMap_pack extends StatefulWidget {
  const flutterMap_pack({super.key});

  @override
  State<flutterMap_pack> createState() => _flutterMap_packState();
}

class _flutterMap_packState extends State<flutterMap_pack> {
  //VARIABLES =====================================

  List<LatLng> _polylineDijkstras = [];
  List<Polyline> _polylinesStaticBus = [];
  List<Marker> _markersStaticBusStand = [];
  List<Marker> _markerRealTimeBus = [];
  List<Marker> _markerBusStand = [];
  String _geoJsonData = '';
  MapController flutterMap_C = MapController();
  final storage = FirebaseStorage.instance;
  DatabaseReference fdb = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _busData = [];
  List<Map<String, dynamic>> allData = [];
  List<Map<String, dynamic>> filteredData = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  String routePressed = 'null';
  bool refereshButtonPressed = false;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  String _currentLocation = '';
  bool isTimerRunning = false;
  late Timer _timer;
  dynamic searchObtained;
  late Position myLocation;
  double minDistance = double.infinity;
  BusStand? nearestBusStand;
  //Search Variables
  Query fdbQuery = FirebaseDatabase.instance.ref().child('BusStands');
  List<Map<String, dynamic>> allDataS = [];
  List<Map<String, dynamic>> filteredDataS = [];
  bool isLoadingS = true;
  TextEditingController searchControllerS = TextEditingController();
  bool isNear = false;
  bool finishedLoad = false;
  bool ShowBusCancelVisible = false;

  // Polyline popup Vars
  List<Marker> _popupDijkstrasMarkers =
      []; // For storing markers at polyline ends
  List AddedBusRoutes = [];

//INIT STATE =======================

  @override
  void initState() {
    fetchData();
    fetchDataS();
    myLoc();
    searchController.addListener(() {
      filterData(searchController.text);
    });

    searchControllerS.addListener(() {
      filterDataS(searchControllerS.text);
    });
    //_loadGeoJsonFromFirebase();

    // _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
    //   fetchBusData();
    // });
    // if (refereshButtonPressed == true) {

    // }
    super.initState();
  }

  void resetAllVars() {
    _stopTimer();
    setState(() {
      _polylineDijkstras = [];

      _polylinesStaticBus = [];
      _markersStaticBusStand = [];

      _markerRealTimeBus = [];

      _markerBusStand = [];

      // Polyline popup Vars
      _popupDijkstrasMarkers = [];
    });
// For storing markers at polyline ends
  }

  void resetMarker() {
    _stopTimer();
    setState(() {
      _markersStaticBusStand = [];
      _markerRealTimeBus = [];
      _markerBusStand = [];

      // Polyline popup Vars
      _popupDijkstrasMarkers = [];
    });
  }

  void resetPolylines() {
    _stopTimer();
    setState(() {
      _polylineDijkstras = [];
      _polylinesStaticBus = [];
    });
  }

  void _startTimerMulti() {
    fetchBusData_Alt();
    if (!isTimerRunning) {
      _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
        fetchBusData_Alt();
      });
      isTimerRunning = true;
    }
  }

  void _startTimerSingle() {
    fetchBusData_Alt();
    if (!isTimerRunning) {
      _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
        fetchBusData_Alt();
      });
      isTimerRunning = true;
    }
  }

  void _stopTimer() {
    setState(() {
      _markerRealTimeBus.clear();
    });
    if (isTimerRunning) {
      _timer.cancel();
      isTimerRunning = false;
    }
  }

  // dispose state

  @override
  void dispose() {
    // TODO: implement dispose
    _timer.cancel();
    super.dispose();
  }

// altered FDB_ Bus request

  void fetchBusData_Alt() async {
    print('Inside Fetch BUs Data ALT Function');
    print(AddedBusRoutes.toString());

    setState(() {
      _markerRealTimeBus.clear();
    });

    List<Map<String, dynamic>> busesWithDistances = [];

    // Simulate a check for a requested route
    bool isRouteRequested =
        checkIfRouteRequested(); // Replace with your actual logic
    if (!isRouteRequested) {
      _stopTimer();
      toastification.show(
        context: context,
        description: Text('No bus routes have been requested!'),
        autoCloseDuration: Duration(seconds: 5),
      );
      return;
    }
    DataSnapshot data_Bus_Route = await fdb.child('bus_routes_N').get();
    // //print(dataSnapshot.value);
    dynamic data_BusRoute = data_Bus_Route.value;
    // List<Map<String, dynamic>> results = [];

    // data.forEach((route, busRoute) {
    //   print(route);
    //   results.add({
    //     'BusRoute': route,
    //   });
    // });
    DataSnapshot dataSnapshot = await fdb.child('BusData').get();
    dynamic data = dataSnapshot.value;
    print('DataRaw: ');
    print(data.toString());
    List<Map<String, dynamic>> results = [];
    String currentHeading = 'NaN';
    // Get current location
    final currentPosition = await Geolocator.getCurrentPosition();
    double currentLat = currentPosition.latitude;
    double currentLng = currentPosition.longitude;

    print('Im here');

    data.forEach((busNP, busData) {
      print(AddedBusRoutes.toString());
      try {
        print(AddedBusRoutes[0].toString());
        if (AddedBusRoutes[0] == busData['route']) {
          print(busData.toString());

          double busLat = double.parse(busData['Lat'].toString());
          double busLng = double.parse(busData['Lng'].toString());
          double PrevBusLat = double.parse(busData['PreviousLat'].toString());
          double PrevBusLng = double.parse(busData['PreviousLng'].toString());

          print('Route Parsing');
          //get the direction of the route,

          String route = busData['route'];
          // List route_SDot = route.split('.');
          // String route_SDot0 = route;
          List route_SUS = route.split('_');
          // print(route_SUS);
          String route_SUS1 = route_SUS[1];
          List route_SD = route_SUS1.split('-');
          print(route_SD);
          String LocA = route_SD[0];
          String LocB = route_SD[1];

          print(LocA);
          print(LocB);

          data_BusRoute.forEach((route, busRoute) {
            // print(route);
            if (route == busData['route']) {
              //Get Cordinates Start and End
              dynamic startLoc = busRoute['first_coordinate'];
              dynamic endLoc = busRoute['last_coordinate'];
              print(startLoc);
              print(endLoc);

              //Calculate Distances
              double distance_Current = Geolocator.distanceBetween(
                  startLoc[0], startLoc[1], busLat, busLng);
              double distance_Past = Geolocator.distanceBetween(
                  startLoc[0], startLoc[1], PrevBusLat, PrevBusLng);

              print(distance_Current);
              print(distance_Past);
              currentHeading = 'NaN';
              if (distance_Past < distance_Current) {
                print('LocB');
                //travelling towards EndLoc

                currentHeading = LocB;
              }
              if (distance_Past > distance_Current) {
                print('LocA');

                currentHeading = LocA;
              }
            }
          });

          // Calculate distance between start, end, and LocA and LocB
          print('Distance Parsing');

          // Calculate the distance between the current location and the bus
          double distance = Geolocator.distanceBetween(
              currentLat, currentLng, busLat, busLng);
          double distanceinKm = distance / 1000;
          String parsedDistance = distanceinKm.toStringAsFixed(3);

          print('Crowd Parsing');

          // Approximate the Crowd values
          String crowd = busData['Crowd'].toStringAsFixed(3);
          double parsedCrowd = double.parse(crowd);
          int intParsedCrowd = parsedCrowd.round();

          print('Direction Parsing');
          // Calculate the bus Direction

          print('Adding Details');
          // Add the bus to the results list with calculated distance
          busesWithDistances.add({
            'Crowd': intParsedCrowd,
            'Driver': busData['Driver'],
            'Lat': busLat,
            'Lng': busLng,
            'NumberP': busNP,
            'route': busData['route'],
            'distance': distanceinKm,
            'parsedDistance': parsedDistance,
            'Heading': currentHeading
          });
        }
      } catch (e) {
        print('Error parsing bus data: $e');
      }
    });

    // Sort the buses based on distance from current location
    busesWithDistances.sort((a, b) => a['distance'].compareTo(b['distance']));

    // Take only the nearest 2 buses
    // results = busesWithDistances.sublist(0, min(busesWithDistances.length, 2));

    results = busesWithDistances;
    // print(results);

    if (results.isNotEmpty) {
      results.forEach((result) {
        _markerRealTimeBus.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(result['Lat'], result['Lng']),
            child: Container(
              width: 80.0,
              height: 80.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          print('Pasring for dialog');
                          int crowd = int.parse(result['Crowd'].toString());
                          String crowdR = 'NaN';
                          if (crowd < 25) {
                            crowdR = 'Low';
                          } else if (crowd < 45 && crowd >= 25) {
                            crowdR = 'Normal';
                          } else if (crowd >= 45) {
                            crowdR = 'Dense Crowd';
                          }
                          return AlertDialog(
                            title: Text('Bus Data'),
                            actions: [
                              Center(
                                child: Column(
                                  children: [
                                    Text('Bus Route: ' +
                                        result['route'].toString()),
                                    Text('Bus Direction Towards: ' +
                                        result['Heading'].toString()),
                                    // need to add the bus direction by caching the past
                                    // direction using gps data, or we can use the bus end stand, and the current
                                    // location with respect to the end and start location and monitor the
                                    // distance
                                    Text('Driver: ' +
                                        result['Driver'].toString()),
                                    Text('Plate No.: ' +
                                        result['NumberP'].toString()),
                                    Text('Approximated Distance: ' +
                                        result['parsedDistance'].toString() +
                                        ' Km'),
                                    Text(
                                        'Crowd: ' + crowd.toString() + ' / 56'),
                                    Text('Crowd: ' + crowdR),
                                    Padding(padding: EdgeInsets.all(10)),
                                    LinearProgressIndicator(value: crowd / 56),
                                  ],
                                ),
                              )
                            ],
                          );
                        },
                      );
                    },
                    child: Icon(
                      Icons.directions_bus,
                      color: Colors.red,
                      size: 30.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
      setState(() {
        _busData = results;
        _markerRealTimeBus = _markerRealTimeBus;
      });
    } else {
      _stopTimer();
      toastification.show(
        context: context,
        description: Text('No buses found within the specified range!'),
        autoCloseDuration: Duration(seconds: 5),
      );
    }
  }

// Helper method to check if a bus route has been requested (implement as needed)
  bool checkIfRouteRequested() {
    return true; // For demonstration purposes, return true
  }

// fetch bus data from FDB ===========================

  void fetchBusData() async {
    setState(() {
      _markerRealTimeBus.clear();
    });
    DataSnapshot dataSnapshot = await fdb.child('BusData').get();
    dynamic data = dataSnapshot.value;
    double busLat = 1.0;
    double busLng = 1.0;
    List<Map<String, dynamic>> results = [];

    // Get your current location
    final currentPosition = await Geolocator.getCurrentPosition();
    double currentLat = currentPosition.latitude;
    double currentLng = currentPosition.longitude;

    data.forEach((route, busData) {
      try {
        busLat = double.parse(busData['Lat']);
        busLng = double.parse(busData['Lng']);
      } on Exception catch (e) {
        // TODO
        busLat = 1.0;
        busLng = 1.0;
      }

      results.add({
        'Crowd': busData['Crowd'],
        'Driver': busData['Driver'],
        'Lat': busLat,
        'Lng': busLng,
        'NumberP': busData['NP'],
        'route': busData['route'],
      });
    });
    print('results: ');
    print(results);
    if (results.length != 0) {
      // Limit results to 5 buses to 5
      results = results.sublist(0, min(results.length, 5));

      results.forEach((result) {
        _markerRealTimeBus.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(
                double.parse(result['Lat']), double.parse(result['Lng'])),
            child: Container(
              width: 80.0, // Explicitly constrain the size of the container
              height: 80.0, // Explicitly constrain the size of the container
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Prevent column from taking infinite height
                children: [
                  InkWell(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            int crowd = int.parse(result['Crowd'].toString());
                            String crowdR = 'NaN';
                            if (crowd < 10) {
                              crowdR = 'Low';
                            } else if (crowd < 30 && crowd >= 10) {
                              crowdR = 'Normal';
                            } else if (crowd >= 30) {
                              crowdR = 'Dense Crowd';
                            }
                            print(crowd);
                            return AlertDialog(
                              title: Text('Bus Data'),
                              actions: [
                                Center(
                                    child: Column(
                                  children: [
                                    Text('Bus Route: ' +
                                        result['route'].toString()),
                                    Text('Driver: ' +
                                        result['Driver'].toString()),
                                    Text('Plate No.: ' +
                                        result['NumberP'].toString()),
                                    Text('Crowd: ' + crowdR),
                                    Padding(padding: EdgeInsets.all(10)),
                                    LinearProgressIndicator(
                                      value: crowd / 42,
                                    )
                                  ],
                                ))
                              ],
                            );
                          });
                    },
                    child: Icon(
                      Icons.directions_bus,
                      color: Colors.red,
                      size: 30.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
      setState(() {
        _busData = results;
        _markerRealTimeBus = _markerRealTimeBus;
      });
    } else {
      _stopTimer();
      toastification.show(
          context: context,
          description: Text('No Busses in 5km radius!'),
          autoCloseDuration: Duration(seconds: 5));
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Pi/180
    double lat1Rad = lat1 * p;
    double lon1Rad = lon1 * p;
    double lat2Rad = lat2 * p;
    double lon2Rad = lon2 * p;

    double dlon = lon2Rad - lon1Rad;
    double dlat = lat2Rad - lat1Rad;

    double a = sin(dlat / 2) * sin(dlat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dlon / 2) * sin(dlon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double d = 6371 * c; // Radius of the Earth in kilometers

    print(d);
    return d;
  }
  // Load GeoJSON from assets ===============================

  Future<void> _loadGeoJsonFromAssets(String route) async {
    try {
      // Load the GeoJSON file from the assets folder
      String geoJsonData =
          await rootBundle.loadString('assets/geoJson/$route.geojson');
      // Parse the GeoJSON data
      final geoJson = jsonDecode(geoJsonData);

      // Extract the coordinates and create polylines
      _polylinesStaticBus =
          List<Polyline>.from(geoJson['features'].map((feature) {
        List<LatLng> points =
            _getPointsFromCoordinates(feature['geometry']['coordinates']);

        return Polyline(
          points: points,
          color: Colors.blue,
          strokeWidth: 4,
        );
      }));

      // Create markers for the start and end points
      geoJson['features'].forEach((feature) {
        List<LatLng> points =
            _getPointsFromCoordinates(feature['geometry']['coordinates']);

        _markersStaticBusStand.add(
          Marker(
            width: 40.0,
            height: 40.0,
            point: points.first,
            child: Icon(Icons.location_pin),
          ),
        );

        _markersStaticBusStand.add(
          Marker(
            width: 40.0,
            height: 40.0,
            point: points.last,
            child: Icon(Icons.location_pin),
          ),
        );
      });

      // Move the location to the midpoint of the route ==================

      List<LatLng> points = _getPointsFromCoordinates(
          geoJson['features'][0]['geometry']['coordinates']);
      LatLng midpoint = _calculateMidpoint(points);

      // Rezoom the map
      flutterMap_C.move(midpoint, 10.5);

      setState(() {
        _geoJsonData = geoJsonData;
      });
    } catch (e) {
      print('Error loading GeoJSON: $e');
    }
  }

// Calculate mid Point =======================

  LatLng _calculateMidpoint(List<LatLng> points) {
    double sumLatitude = 0;
    double sumLongitude = 0;

    for (LatLng point in points) {
      sumLatitude += point.latitude;
      sumLongitude += point.longitude;
    }

    double averageLatitude = sumLatitude / points.length;
    double averageLongitude = sumLongitude / points.length;

    return LatLng(averageLatitude, averageLongitude);
  }

// Cordinate Correction ======================

  List<LatLng> _correctCoordinates(dynamic coordinates) {
    try {
      // Check if already a list of LatLng objects
      if (coordinates is List<LatLng>) {
        return coordinates;
      }
      // Otherwise, parse as raw coordinate pairs
      else if (coordinates is List) {
        return coordinates.map((coord) {
          if (coord is List &&
              coord.length == 2 &&
              coord[0] is num &&
              coord[1] is num) {
            return LatLng(coord[1], coord[0]); // Swap to [latitude, longitude]
          } else {
            print('Invalid coordinate found: $coord');
            throw FormatException('Invalid coordinate format');
          }
        }).toList();
      } else {
        print('Unexpected coordinate structure: $coordinates');
        throw FormatException('Invalid coordinate format');
      }
    } catch (e) {
      print('Error in parsing coordinates: $e');
      throw FormatException('Invalid coordinate format');
    }
  }

// get points from cordinates ==========================

  List<LatLng> _getPointsFromCoordinates(dynamic coordinates) {
    if (coordinates is List) {
      return coordinates.map((coord) {
        if (coord is List &&
            coord.length == 2 &&
            coord[0] is num &&
            coord[1] is num) {
          // Check if the coordinates are in the format of [longitude, latitude]
          if (coord[0] > coord[1]) {
            // Coordinates are in the format of [longitude, latitude]
            return LatLng(coord[1], coord[0]);
          } else {
            // Coordinates are in the format of [latitude, longitude]
            return LatLng(coord[0], coord[1]);
          }
        } else {
          print('Invalid coordinate found: $coord');
          throw FormatException('Invalid coordinate format');
        }
      }).toList();
    } else {
      print('Coordinates are not in a list format: $coordinates');
      throw FormatException('Invalid coordinate format');
    }
  }

// fetch Realtime database data, routes ===================

  Future<void> fetchData() async {
    DataSnapshot dataSnapshot = await fdb.child('bus_routes_N').get();
    //print(dataSnapshot.value);
    dynamic data = dataSnapshot.value;
    List<Map<String, dynamic>> results = [];

    data.forEach((route, busRoute) {
      print(route);
      results.add({
        'BusRoute': route,
      });
    });
    setState(() {
      allData = results;
      filteredData = results;
      isLoading = false;
    });
  }

// filter fetched data ==============================

  void filterData(String query) {
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) {
      results = allData;
    } else {
      results = allData
          .where((busRoute) => busRoute['BusRoute']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
    print(results);
    setState(() {
      filteredData = results;
    });
  }

// LOCATION persmission

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

  // get myLocation ==========================================

  void myLoc() async {
    myLocation = await Geolocator.getCurrentPosition();
  }

  //A* algo ===============================================

  // saerch function
  Future<void> fetchDataS() async {
    DataSnapshot dataSnapshot = await fdb.child('formatted_Bus').get();

    final data = dataSnapshot.value as List<dynamic>;
    List<Map<String, dynamic>> results = [];

    data.forEach((busStand) {
      results.add({
        'Name': busStand['Name'],
        'Longitude': busStand['Longitude'],
        'Latitude': busStand['Latitude'],
      });
    });

    setState(() {
      allDataS = results;
      filteredDataS = results;
      isLoadingS = false;
    });
  }

  void filterDataS(String query) {
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) {
      results = allDataS;
    } else {
      results = allDataS
          .where((busStand) => busStand['Name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredDataS = results;
    });
  }

// function for getting DJISKTRAS from python

//Check for data availability

  Future checkIfAvailable(start, end) async {
    dynamic processedRef = await fdb.child('toBeProcessed').get();
    dynamic snapshot = processedRef.value;
    print('In checkAvailable Func');
    print(start);
    print(end);
    print('lets start with the loop!');

    String localReturnFunc = 'NaN';

    snapshot.forEach((key, value) {
      print(value);
      if (value['start'] == start &&
          value['end'] == end &&
          value['process'] == 'Processed') {
        print('Data is already computed!');
        localReturnFunc = 'AlreadyComputed';
      }

      if (value['start'] == start &&
          value['end'] == end &&
          value['process'] == 'Cannot') {
        print('Data is not available in Map!');
        localReturnFunc = 'CannotCompute';
      }
    });

    if (localReturnFunc == 'AlreadyComputed') {
      return '1';
    }
    if (localReturnFunc == 'CannotCompute') {
      return '2';
    } else {
      return '3';
    }
  }

// Set Data to Process;

  // Function to receive processed route data (in terms of bus stand names) from Firebase
  Future<void> setDataToProcess(start, end) async {
    DatabaseReference processedRef = fdb.child('processed_routes');
    Map dataToProcess = {'start': start, 'end': end, 'process': 'NaN'};
    //Push the data and wait for confirmation
    await fdb.child('toBeProcessed').push().set(dataToProcess);

    DataSnapshot snapshot = await processedRef.get();

    if (snapshot.value != null) {
      Map<String, dynamic> routes =
          Map<String, dynamic>.from(snapshot.value as Map);

      for (var route in routes.values) {
        List<dynamic> busStands =
            route['bus_stands']; // Assume route data is in bus stand names
        print("Route: ${busStands.join(' -> ')}");
      }
    } else {
      print("No processed routes found.");
    }
  }

  // Function to receive processed route data (in terms of bus stand names) from Firebase
  Future getProcessedRoute(start, end) async {
    DatabaseReference processedRef = fdb.child('processed_routes');
    DataSnapshot snapshot = await processedRef.get();

    if (snapshot.value != null) {
      Map<String, dynamic> routes =
          Map<String, dynamic>.from(snapshot.value as Map);

      for (var route in routes.values) {
        List<dynamic> busStands =
            route['bus_stands']; // Assume route data is in bus stand names
        print("Route: ${busStands.join(' -> ')}");
      }
    } else {
      print("No processed routes found.");
    }
  }

  // find nearest bus stand

  Future findNearestBusStation(Position userLocation) async {
    DataSnapshot dataSnapshot = await fdb.child('formatted_Bus').get();

    final data = dataSnapshot.value as List<dynamic>;
    List<Map<String, dynamic>> results = [];

    data.forEach((busStand) {
      results.add({
        'Name': busStand['Name'],
        'Longitude': busStand['Longitude'],
        'Latitude': busStand['Latitude'],
      });
      final distance = calculateDistance(userLocation.latitude,
          userLocation.longitude, busStand['Latitude'], busStand['Longitude']);
      print('Distance: ');
      print(distance);
      if (distance < minDistance) {
        minDistance = distance;

        nearestBusStand = BusStand(
          name: busStand['Name'],
          latitude: busStand['Latitude'],
          longitude: busStand['Longitude'],
        );
      }
    });
    setState(() {
      print(nearestBusStand?.name);
      isNear = true;
    });
    return nearestBusStand;
  }

// new function to draw ployline djikstras
  // Future<void> _fetchProcessedRoutes() async {
  //   DataSnapshot snapshot = await fdb.child('routesProcessed').get();

  //   if (snapshot.value != null) {
  //     Map<String, dynamic> routes =
  //         Map<String, dynamic>.from(snapshot.value as Map);

  //     List<Polyline> newPolylines = [];
  //     for (var routeKey in routes.keys) {
  //       var route = routes[routeKey];
  //       List<dynamic> segments = route['segments'];

  //       List<LatLng> latLngList = [];
  //       for (var segment in segments) {
  //         // Extract start and end coordinates
  //         LatLng start = LatLng(segment['start'][0], segment['start'][1]);
  //         LatLng end = LatLng(segment['end'][0], segment['end'][1]);

  //         // Add start and end points to the LatLng list if not already added
  //         if (latLngList.isEmpty || latLngList.last != start) {
  //           latLngList.add(start);
  //         }
  //         latLngList.add(end);
  //       }

  //       // Create a polyline for the current route
  //       Polyline polyline = Polyline(
  //         points: latLngList,
  //         color: Colors.red,
  //         strokeWidth: 4.0,
  //       );
  //       newPolylines.add(polyline);
  //     }

  //     // Update the state to render the polylines
  //     setState(() {
  //       _polylineDijkstras = newPolylines;
  //       finishedLoad = true;
  //     });
  //   }
  // }

// Extract Polylines created from python through firebase ====================

  void _processedPolyline(start, end) async {
    print('Inside processed Polyline Func');
    dynamic data = await fdb.child('routesProcessed').get();
    dynamic dataSnapshot = data.value;
    print(dataSnapshot.toString());
    AddedBusRoutes = [];
    List<LatLng> points = [];
    List<Marker> stands = [];

    dataSnapshot.forEach((key, value) {
      if (start == value['start'] && end == value['end']) {
        print('INITIAL STEPS: ');
        print(value['start']);
        print(value['end']);
        print('Value in Segemnts Raw: ');
        print(value['segments']);
        print('check first  Value: ');
        //it ounly outputs the fisrt value, therfore parse as list.
        print(value['segments'][0]);

        dynamic dataEx = value['segments'];
        dynamic dataBusses = value['uniqueBusStands'];
        print('Im here! III');
        print(dataEx.toString());

        print('Unique Bus Stands and the Start End Cordinates');
        print(dataBusses.toString());

        dataBusses.forEach((value3) {
          // Convert data from list to single Strings or Doubles to plot the intersection
          var startPoint = value3['start'];
          var endPoint = value3['end'];
          String busRoute = value3['source_file'];

          // Parse the busRoute
          print(busRoute);
          print('Splitted Data');
          List SplittedBus = busRoute.split('.');
          print(SplittedBus.toString());
          List BusNoName = SplittedBus[0].split('_');
          AddedBusRoutes.add(SplittedBus[0]);

          stands.add(Marker(
            width: 40,
            height: 40,
            point: LatLng(startPoint[0], startPoint[1]),
            child: Container(
              width: 80.0, // Explicitly constrain the size of the container
              height: 80.0, // Explicitly constrain the size of the container
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Prevent column from taking infinite height
                children: [
                  InkWell(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              // title: Text('Change Bus Route to: '+ busRoute.toString()),
                              actions: [
                                Center(
                                  child: Column(
                                    children: [
                                      Padding(padding: EdgeInsets.all(10)),
                                      Text('Take the Following Bus',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      Text(
                                          'Bus Number: ' +
                                              BusNoName[0].toString(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      Text('Bus Route: ' + BusNoName[1],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      // Padding(
                                      //     padding: EdgeInsets.only(top: 10)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          });
                    },
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.black,
                      size: 30.0,
                    ),
                  ),
                ],
              ),
            ),
          ));
        });

        dataEx.forEach((value2) {
          // print('INSIDE THE DOUBLE LOOP: ');
          // //Now correct, the error was the var endPoint, was taking values from 'value'
          // print(value2);

          // start and end points of each polyline lines

          var startPoint = value2['start'];
          var endPoint = value2['end'];

          // Create marker at the mid point of the polyline short line
          // LatLng midPoint = LatLng(
          //   (startPoint[0] + endPoint[1]) / 2,
          //   (startPoint[0] + endPoint[1]) / 2,
          // );

          // This is a marker code

          // stands.add(Marker(width: 40,height: 40,
          //   point: LatLng(startPoint[0],startPoint[1]),
          //   child: Container(
          //     width: 80.0, // Explicitly constrain the size of the container
          //     height: 80.0, // Explicitly constrain the size of the container
          //     child: Column(
          //       mainAxisSize: MainAxisSize
          //           .min, // Prevent column from taking infinite height
          //       children: [
          //         InkWell(
          //           onTap: () {
          //             showDialog(
          //                 context: context,
          //                 builder: (context) {
          //                   return AlertDialog(
          //                     title: Text(sourceFile.toString()),
          //                   );
          //                 });
          //           },
          //           child: Icon(
          //             Icons.train,
          //             color: Colors.blueAccent,
          //             size: 1.0,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // )

          points.add(LatLng(startPoint[0], startPoint[1]));
          points.add(LatLng(endPoint[0], endPoint[1]));
        });
      }
    });

    print('the points: ');
    print(points);

    // Now we need to
    setState(() {
      _popupDijkstrasMarkers = [];
      _polylineDijkstras = [];
      _popupDijkstrasMarkers = stands;
      _polylineDijkstras = points;
      finishedLoad = true;
      Navigator.of(context).pop();
    });
  }

  // WIDGET TREEE ==================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              tooltip: 'Bus Routes',
              child: Icon(Icons.directions_transit),
              onPressed: () {
                transitLocate(context);
                setState(() {
                  _markerBusStand = [];
                  _popupDijkstrasMarkers = [];
                  _polylineDijkstras = [];
                });
              },
            ),
            Padding(padding: EdgeInsets.all(5)),
            FloatingActionButton(
              tooltip: 'Show Bus',
              child: Icon(Icons.bus_alert_rounded),
              onPressed: () {
                print('polylineP');
                print(_polylineDijkstras);
                print('polylineP');
                print(_polylinesStaticBus);
                if (_polylineDijkstras.isEmpty && _polylinesStaticBus.isEmpty) {
                  toastification.show(
                      context: context,
                      description: Text(
                          'No directions selected! Please select a bus route or request direction'));
                } else if (_polylineDijkstras.isEmpty &&
                    _polylinesStaticBus.isNotEmpty) {
                  // For Dijkstras Route
                  //resetMarker();
                  //resetPolylines();
                  setState(() {
                    ShowBusCancelVisible = true;
                  });
                  _startTimerMulti();
                } else if (_polylineDijkstras.isNotEmpty &&
                    _polylinesStaticBus.isEmpty) {
                  // FOr Static Route

                  //resetMarker();
                  //resetPolylines();
                  setState(() {
                    ShowBusCancelVisible = true;
                  });
                  print(AddedBusRoutes.toString());
                  _startTimerSingle();
                }
              },
            ),
            Padding(padding: EdgeInsets.all(5)),
            Visibility(
                visible: ShowBusCancelVisible,
                child: FloatingActionButton(
                    tooltip: 'Real Time Bus Cancel',
                    child: Icon(Icons.cancel),
                    onPressed: () {
                      _stopTimer();
                      setState(() {
                        ShowBusCancelVisible = false;
                      });
                    })),
            Padding(padding: EdgeInsets.all(5)),
            FloatingActionButton(
              tooltip: 'Bus Stand Locate',
              child: Icon(Icons.transit_enterexit),
              onPressed: () {
                busStandLocate(context);
                setState(() {
                  _markerBusStand = [];
                  _popupDijkstrasMarkers = [];
                  _polylineDijkstras = [];
                });
              },
            ),
            Padding(padding: EdgeInsets.all(5)),
            FloatingActionButton(
              tooltip: 'Calculate Route',
              child: Icon(Icons.search),
              onPressed: () async {
                _stopTimer();
                setState(() {
                  _polylineDijkstras = [];
                  _polylinesStaticBus = [];
                  _markersStaticBusStand = [];
                  AddedBusRoutes = [];
                });

                if (checkIfStandIsAvailable()) {
                  print(findNearestBusStation(myLocation));
                  dynamic nearR = await findNearestBusStation(myLocation);
                  print('In button Here');

                  // WIDGET

                  showModalBottomSheet(
                    context: context,
                    isDismissible: false,
                    useRootNavigator: false,
                    builder: (BuildContext context) {
                      return PopScope(
                        canPop: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              isNear
                                  ? Text('Start Bus Stand: ' +
                                      nearR.name.toString())
                                  : CircularProgressIndicator(),
                              Text('End Bus Stand: ' + searchObtained['Name']),
                              SizedBox(height: 20),
                              Text(
                                'Calculating best and efficient route!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 20),
                              LinearProgressIndicator(),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  // Djikstras Algorithm path

                  String routeAvailable = await checkIfAvailable(
                      nearR.name, searchObtained['Name']);

                  print('route availability?: ');
                  print(routeAvailable);
                  //1 already computed, 2 cannot compute, 3 compute

                  if (routeAvailable == '1') {
                    // data retrieval ----------------------------------------------
                    _processedPolyline(
                        nearR.name.toString(), searchObtained['Name']);
                  }
                  if (routeAvailable == '3') {
                    await setDataToProcess(nearR.name, searchObtained['Name']);
                    String processOutput = await checkForNaNtoProcessed(
                        nearR.name, searchObtained['Name']);
                    if (processOutput == 'processComplete') {
                      setState(() {
                        finishedLoad = true;
                      });
                      _processedPolyline(
                          nearR.name.toString(), searchObtained['Name']);
                    }
                    if (processOutput == 'processIncomplete') {
                      setState(() {
                        finishedLoad = true;
                      });
                      toastification.show(
                        context: context,
                        description: Text('Cannot be computed!'),
                        showProgressBar: false,
                        autoCloseDuration: Duration(seconds: 5),
                      );
                      Navigator.of(context).pop();
                    }
                    if (processOutput == 'timeout') {
                      setState(() {
                        finishedLoad = true;
                      });
                      toastification.show(
                        context: context,
                        description: Text('System timeout!'),
                        showProgressBar: false,
                        autoCloseDuration: Duration(seconds: 5),
                      );
                      Navigator.of(context).pop();
                    }
                  }

                  if (routeAvailable == '2') {
                    toastification.show(
                      context: context,
                      description: Text(
                          'Route cannot be computed, No routes within 100m'),
                      autoCloseDuration: Duration(seconds: 5),
                      showProgressBar: false,
                    );
                    Navigator.of(context).pop();
                  }
                } else {
                  toastification.show(
                      context: context,
                      autoCloseDuration: Duration(seconds: 5),
                      showProgressBar: false,
                      description: Text('Bus stand not selected!'));
                }
              },
            ),
            Padding(padding: EdgeInsets.all(25))
          ],
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniEndDocked,
        body: FlutterMap(
          mapController: flutterMap_C,
          options: MapOptions(
            // interactionOptions: InteractionOptions(pinchZoomThreshold: 1,pinchZoomWinGestures: 1), // dont know why it doest work
            initialCenter:
                LatLng(6.914667, 79.972941), // Center the map over London
            initialZoom: 9.2,
          ),
          children: [
            TileLayer(
              // Display map tiles from any source
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
              userAgentPackageName: 'com.tms.app',
              // And many more recommended properties!
            ),
            RichAttributionWidget(
              // Include a stylish prebuilt attribution widget that meets all requirments
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(Uri.parse(
                      'https://openstreetmap.org/copyright')), // (external)
                ),
                // Also add images...
              ],
            ),

            // PopupMarkerLayer(
            //     options: PopupMarkerLayerOptions(markers: _popupDijkstrasMarkers)),

            PolylineLayer(polylines: [
              Polyline(
                points: _polylineDijkstras,
                color: Colors.blue,
                strokeWidth: 4.0,
              )
            ]),
            PolylineLayer(polylines: _polylinesStaticBus),
            MarkerLayer(markers: _markersStaticBusStand),
            MarkerLayer(markers: _markerRealTimeBus),
            MarkerLayer(markers: _markerBusStand),
            MarkerLayer(markers: _popupDijkstrasMarkers),
            CurrentLocationLayer(),

            // GeoJSONLayer(
            //   geoJSONFeatures: _geoJSONFeatures,
            //   pointStyle: PointStyle(
            //     color: Colors.blue,
            //     radius: 10,
            //   ),
            //   lineStyle: LineStyle(
            //     color: Colors.red,
            //     strokeWidth: 2,
            //   ),
            //   polygonStyle: PolygonStyle(
            //     color: Colors.green,
            //     borderColor: Colors.black,
            //     borderWidth: 2,
            //   ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> transitLocate(BuildContext context) {
    return showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        //String _searchQuery = '';
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Column(
              children: [
                Padding(padding: EdgeInsets.all(15)),
                Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Bus Routes',
                    style: TextStyle(
                      fontSize: 18,
                      // color: Colors.white,
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(4)),
                Container(
                  width: 300,
                  child: TextField(
                    onChanged: (query) {
                      setState(() {
                        filterData(query);
                      }); // Update the state
                    },
                    keyboardType: TextInputType.text,
                    controller: searchController,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: "Search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      //print(filteredData);
                      final busRoute = filteredData[index]['BusRoute'];
                      return InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Selected Bus Route'),
                              actions: [
                                Center(
                                  child: Column(
                                    children: [
                                      Text(busRoute.toString()),
                                      Padding(
                                          padding: EdgeInsets.only(top: 10)),
                                      ElevatedButton(
                                        onPressed: () {
                                          // On PRESSING

                                          setState(() {
                                            _polylinesStaticBus = [];
                                            _markersStaticBusStand = [];
                                            AddedBusRoutes = [];
                                          });

                                          routePressed = busRoute;
                                          print(
                                              'Before adding to route Name to called by Bus');

                                          AddedBusRoutes.add(routePressed);
                                          _loadGeoJsonFromAssets(routePressed);
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                          searchController.clear();
                                          // Navigator.push(
                                          //   context,
                                          //   MaterialPageRoute(
                                          //     builder: (context) => mapBody(
                                          //       busStand['Name'],
                                          //       busStand['Latitude'],
                                          //       busStand['Longitude'],
                                          //     ),
                                          //   ),
                                          // );
                                        },
                                        child: Text('Show On Map'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Card(
                          child: Column(
                            children: [
                              Text(''),
                              Text(filteredData[index]['BusRoute'].toString()),
                              Text(''),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<dynamic> busStandLocate(BuildContext context) {
    return showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        //String _searchQuery = '';
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Column(
              children: [
                Padding(padding: EdgeInsets.all(15)),
                Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Bus Stands',
                    style: TextStyle(
                      fontSize: 18,
                      // color: Colors.white,
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(4)),
                Container(
                  width: 300,
                  child: TextField(
                    onChanged: (query) {
                      setState(() {
                        filterData(query);
                      }); // Update the state
                    },
                    keyboardType: TextInputType.text,
                    controller: searchControllerS,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: "Search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: isLoadingS
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : ListView.builder(
                          itemCount: filteredDataS.length,
                          itemBuilder: (context, index) {
                            final busStand = filteredDataS[index];
                            return InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Selected Bus Stand'),
                                    actions: [
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(busStand['Name']),
                                            Padding(
                                                padding: EdgeInsets.all(10)),
                                            ElevatedButton(
                                              onPressed: () {
                                                print(busStand);
                                                searchObtained = busStand;

                                                showMarker_stand(busStand);
                                                // aStarPathfinding(LatLng(myLocation.latitude, myLocation.longitude), LatLng(busStand['Latitude'], busStand['Longitude']), busStands, routes)
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                                searchControllerS.clear();
                                              },
                                              child: Text('Show On Map'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Card(
                                child: Column(
                                  children: [
                                    Text(''),
                                    Text(busStand['Name']),
                                    Text(''),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showMarker_stand(Map<String, dynamic> busStand) {
    setState(() {
      _markerBusStand = [];
    });

    _markerBusStand.add(
      Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(busStand['Latitude'], busStand['Longitude']),
        child: Container(
          width: 80.0, // Explicitly constrain the size of the container
          height: 80.0, // Explicitly constrain the size of the container
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Prevent column from taking infinite height
            children: [
              InkWell(
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(busStand['Name'].toString()),
                        );
                      });
                },
                child: Icon(
                  Icons.train,
                  color: Colors.blueAccent,
                  size: 30.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    setState(() {
      _markerBusStand = _markerBusStand;
    });
  }

  Future checkForNaNtoProcessed(start, end) async {
    print('In checkForNaNtoProcessed Func');
    print(start);
    print(end);
    print('lets start with the loop!');

    final timeoutForLoop = Stopwatch();
    timeoutForLoop.start();
    print(timeoutForLoop.elapsedMilliseconds);

    bool shouldExitLoop = false; // Control variable
    bool cannot = false;

    while (shouldExitLoop == false) {
      // one minute
      dynamic processedRef = await fdb.child('toBeProcessed').get();
      dynamic snapshot = processedRef.value;
      snapshot.forEach((key, value) {
        print(value);
        if (value['start'] == start && value['end'] == end) {
          if (value['process'] == 'Processed') {
            shouldExitLoop = true; // Set control variable to true
            cannot = false;
            return; // Exit the forEach loop
          } else if (value['process'] == 'Cannot') {
            shouldExitLoop = true; // Set control variable to true
            cannot = true;
            return; // Exit the forEach loop
          }
        }
      });
      print(shouldExitLoop);
      if (shouldExitLoop) {
        break; // Exit the while loop
      }
// it time is met break the loop too
      if (timeoutForLoop.elapsedMilliseconds >= 60000) {
        print('loop timout');
        break;
      }
      print(timeoutForLoop.elapsedMilliseconds.toString());
      await Future.delayed(Duration(seconds: 1));
    }

    timeoutForLoop.stop();

    if (shouldExitLoop == true && cannot == false) {
      return 'processComplete';
    }
    if (shouldExitLoop == true && cannot == true) {
      return 'processIncomplete';
    }
    if (shouldExitLoop == false && cannot == false) {
      return 'timeout';
    }
  }

  bool checkIfStandIsAvailable() {
    print('SearchObtain');
    if (searchObtained['Name'] == null || searchObtained['Name'] == '') {
      return false;
    } else {
      return true;
    }
  }
}
