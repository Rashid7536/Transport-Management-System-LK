import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


class Database_mthds {
  final ref = FirebaseDatabase.instance.ref();
  //Query ref2 = FirebaseDatabase.instance.ref().child('patientData');
  DateTime getNow = DateTime.now();
  //final math = Random().nextBool();

  //ADD USER
  Future addUser(firstName, userName) async {
    int DayNow = getNow.day;
    int YearNow = getNow.year;
    int MonthNow = getNow.month;
    String dateNow = DayNow.toString() +
        "/" +
        MonthNow.toString() +
        "/" +
        YearNow.toString();

    //String keyF = key.toString();
    Map<String, String> details = {
      'Fname': firstName,
      'userName': userName,
      'updateTime': dateNow,
    };
    //print("Success");
    await ref.child('users').push().set(details);
  }


Future<void> sendStartAndEndBusStands(String startStand, String endStand, double startLat, double startLng, double endLat, double endLng) async {
  DatabaseReference ref = FirebaseDatabase.instance.ref('requested_route');
  await ref.set({
    'start': {
      'name': startStand,
    },
    'end': {
      'name': endStand,
    }
  });
}


}

class authentication {
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<bool> checkUserAvailable() async {
    User? user = auth.currentUser;
    if (user != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<String> getUser() async {
    String? user = auth.currentUser?.displayName;
        if (user != null) {
      return user;
    } else {
      return 'Not logged in';
    }
  }
}

class BusStand {
  final String name;
  final double latitude;
  final double longitude;

  BusStand({required this.name, required this.latitude, required this.longitude});
}
