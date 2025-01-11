import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:geocoding/geocoding.dart';
//import 'package:geolocator/geolocator.dart';

class mapBody extends StatefulWidget {
  final double longit;
  final double latit;
  final String name_1;
  mapBody(this.name_1, this.latit, this.longit, {super.key});

  @override
  State<mapBody> createState() => _mapBodyState();
}

class _mapBodyState extends State<mapBody> {
  Timer? timer;
  final Fdb = FirebaseDatabase.instance.ref();
  List busDataNP = [];
  List busDataLat = [];
  List busDataLng = [];
  List busDataCrowd = [];
  double lat_p = 0;
  double lng_p = 0;
  @override
  void initState() {
    super.initState();
    getLoc();

    timer = Timer.periodic(Duration(seconds: 2), (Timer t) {
      getBus();
      locateBus();
    });
  }

  double latitude_cur = 0;
  double longitude_cur = 0;
  int stateVar = 0;
  MapController mapController = MapController.publicTransportationLayer(
    initPosition: GeoPoint(latitude: 6.914667, longitude: 79.972941),
  );

  void initPostion() async {
    if (widget.name_1 == 'init') {
      mapController = MapController.publicTransportationLayer(
        initPosition: GeoPoint(latitude: 6.914667, longitude: 79.972941),
      );
    } else {
      mapController = MapController.publicTransportationLayer(
        initPosition:
            GeoPoint(latitude: widget.latit, longitude: widget.longit),
      );
    }
    markerLoc();
  }

  void markerLoc() async {
    await mapController.addMarker(
        GeoPoint(latitude: widget.latit, longitude: widget.longit),
        angle: 0);
  }

  void getBus() async {
    dynamic output = await Fdb.child('BusData').get();
    print(output.value);
    print('here');
    dynamic data = output.value as Map;
    data.forEach((key, busdata) {
      print(busdata['NP'].toString());
      busDataNP.add(busdata['NP']);
      busDataLat.add(busdata['Lat']);
      busDataLng.add(busdata['Lng']);
      busDataCrowd.add(busdata['Crowd']);
    });
    print('BusData: ' + busDataNP.toString());
  }

  void drawRoad() async {
    getLoc();
    await mapController.removeLastRoad();
    print('currrenLat:' + latitude_cur.toString());
    print('currrenLon:' + longitude_cur.toString());
    RoadInfo roadInfo = await mapController.drawRoad(
      GeoPoint(latitude: latitude_cur, longitude: longitude_cur),
      GeoPoint(latitude: widget.latit, longitude: widget.longit),
      roadType: RoadType.car,

      //remember to use when road system shows bad route, later improvement, need algo for this
      // intersectPoint: [
      //   GeoPoint(latitude: 47.4361, longitude: 8.6156),
      //   GeoPoint(latitude: 47.4481, longitude: 8.6266)
      // ],
      roadOption: RoadOption(
          roadWidth: 12,
          roadColor: Colors.blue,
          zoomInto: true,
          roadBorderWidth: 5,
          roadBorderColor: Colors.black),
    );
    Fluttertoast.showToast(
        msg: 'Distance' + roadInfo.distance.toString() + 'km');
    print("${roadInfo.distance}km");
    print("${roadInfo.duration}sec");
    print("${roadInfo.instructions}");
  }

  void locateBus() async {
    await mapController
        .removeMarker(GeoPoint(latitude: lat_p, longitude: lng_p));
    double lat = double.parse(busDataLat[0]);
    double lng = double.parse(busDataLng[0]);
    await mapController.addMarker(
        GeoPointWithOrientation(latitude: lat, longitude: lng, angle: 0),
        markerIcon: MarkerIcon(
          icon: Icon(Icons.bus_alert),
        ));
    lat_p = lat;
    lng_p = lng;

    busDataNP.clear();
    busDataLat.clear();
    busDataLng.clear();
    busDataCrowd.clear();
  }

  @override
  Widget build(BuildContext context) {
    initPostion();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Map',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
              onPressed: () async {
                print(busDataCrowd.toString());
                double lat = double.parse(busDataLat[0]);
                double lng = double.parse(busDataLng[0]);
                var np = busDataNP[0];
                var crowd = busDataCrowd[0];
                // await mapController.moveTo(GeoPointWithOrientation(
                //     latitude: 6.914667, longitude: 79.972941, angle: 0));
                // await mapController.addMarker(GeoPointWithOrientation(
                //     latitude: 6.914667, longitude: 79.972941, angle: 0));

                await mapController.moveTo(GeoPointWithOrientation(
                    latitude: lat, longitude: lng, angle: 0));

                Fluttertoast.showToast(
                    msg: 'lat: ' +
                        lat.toString() +
                        '\n' +
                        'lng: ' +
                        lng.toString() +
                        '\n' +
                        'NP: ' +
                        np.toString() +
                        '\n' +
                        'Crowd: ' +
                        crowd.toString());

                // showDialog(
                //     context: context,
                //     builder: (context) => AlertDialog(
                //           title: Text('Bus Data'),
                //           actions: [
                //             ListView.builder(
                //                 itemCount: busData.length,
                //                 itemBuilder: (context, index) {
                //                   var lat = busData[index]['Lat'];
                //                   var lng = busData[index]['Lng'];
                //                   var np = busData[index]['NP'];
                //                   var crowd = busData[index]['Crowd'];

                //                   return InkWell(
                //                     onTap: () {
                //                       Navigator.pop(context);
                //                       Fluttertoast.showToast(
                //                           msg: 'lat: ' +
                //                               lat.toString() +
                //                               '\n' +
                //                               'lng: ' +
                //                               lng.toString() +
                //                               '\n' +
                //                               'NP: ' +
                //                               np.toString() +
                //                               '\n' +
                //                               'Crowd: ' +
                //                               crowd.toString() +
                //                               '\n');
                //                     },
                //                   );
                //                 })
                //           ],
                //         ));
              },
              child: Icon(Icons.track_changes)),
          Padding(padding: EdgeInsets.all(5)),
          FloatingActionButton(
            onPressed: () {
              drawRoad();
            },
            child: Icon(Icons.mode_of_travel),
          ),
          Padding(padding: EdgeInsets.all(5)),
          FloatingActionButton(
              child: Icon(Icons.location_on),
              onPressed: () async {
                print("name: " + widget.name_1.toString());
                if (widget.name_1 == 'Init') {
                  //mapController.init();
                  mapController.enableTracking(enableStopFollow: true);
                  mapController.currentLocation();
                  //getLoc();
                  // Use the geocoding package to get the address
                  List<Placemark> placemarks = await placemarkFromCoordinates(
                      latitude_cur, longitude_cur);
                  Placemark place = placemarks[0];
                  print(place.toString());
                } else {
                  print('FromSearch');

                  mapController.enableTracking(enableStopFollow: true);
                  mapController.currentLocation();
                }
              }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: OSMFlutter(
                controller: mapController,
                mapIsLoading: Center(
                  child: CircularProgressIndicator(),
                ),
                onMapIsReady: (p0) async {
                  await mapController.setZoom(stepZoom: 12);
                  if (widget.name_1 == 'Init') {
                    print('Init');
                    await mapController.moveTo(GeoPointWithOrientation(
                        latitude: 6.914667, longitude: 79.972941, angle: 0));
                    await mapController.addMarker(GeoPointWithOrientation(
                        latitude: 6.914667, longitude: 79.972941, angle: 0));
                    await mapController.setZoom(zoomLevel: 13);
                  } else {
                    print('FromSearch');
                    mapController.moveTo(GeoPointWithOrientation(
                        latitude: widget.latit,
                        longitude: widget.longit,
                        angle: 0));
                    //step size doesnt work correctly
                    await mapController.setZoom(zoomLevel: 13);
                    mapController.addMarker(GeoPointWithOrientation(
                        latitude: widget.latit,
                        longitude: widget.longit,
                        angle: 0));
                    // mapController.disabledTracking();
                    // mapController.enableTracking();
                  }
                },
                osmOption: OSMOption(
                    zoomOption: ZoomOption(initZoom: 13),
                    showContributorBadgeForOSM: true,
                    // userTrackingOption:
                    //     UserTrackingOption(enableTracking: true),
                    userLocationMarker: UserLocationMaker(
                        personMarker: MarkerIcon(
                            icon: Icon(
                          Icons.circle,
                          size: 48,
                        )),
                        directionArrowMarker: MarkerIcon(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            //size: 48,
                          ),
                        ))),
              ),
            )
          ],
        ),
      ),
    );
  }

  void getLoc() async {
    GeoPoint currentLocation = await mapController.myLocation();
    // Get the coordinates
    latitude_cur = currentLocation.latitude;
    longitude_cur = currentLocation.longitude;
  }
}
