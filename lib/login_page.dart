import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:leaflet_test/database.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:leaflet_test/mainPage.dart';
import 'package:leaflet_test/signUp.dart';
import 'package:toastification/toastification.dart';

class login_p extends StatefulWidget {
  const login_p({super.key});

  @override
  State<login_p> createState() => _login_pState();
}

class _login_pState extends State<login_p> {
  //final fdb = FirebaseDatabase.instance;
  final fauth = FirebaseAuth.instance;
  final nameControl = TextEditingController();
  final passControl = TextEditingController();
  // final otpControl = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    authentication().checkUserAvailable().then((value) {
      if (value == true) {
        print(authentication().getUser());
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => reportPage()));
      }

      if (value == false) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //backgroundColor: Colors.blueGrey[200],
        body: SafeArea(
      child: Center(
        child: SizedBox(
          width: 250,
          height: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(padding: EdgeInsets.only(top: 20)),
                Text(
                  'WELCOME',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Sri Lanka's Transport\nManagement System",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Padding(padding: EdgeInsets.only(top: 20)),
                Container(
                  child: CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/transit_test.jpg',
                    ),
                  ),
                  height: 200,
                  width: 200,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                ),
                Padding(padding: EdgeInsets.all(10)),
                TextField(
                  controller: nameControl,
                  decoration: InputDecoration(
                    filled: true,
                    //fillColor: Colors.white,
                    //hintText: "Username",
                    prefixIcon: Icon(Icons.account_circle),
                    labelText: "     Type your username",
                    // border: OutlineInputBorder(
                    //     borderRadius: BorderRadius.circular(50))
                  ),
                ),
                Padding(padding: EdgeInsets.all(10)),
                TextField(
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  controller: passControl,
                  decoration: InputDecoration(
                    filled: true,
                    //hintText: "Username",
                    prefixIcon: Icon(Icons.lock),
                    labelText: "     Type your password",
                    // border: OutlineInputBorder(
                    //     borderRadius: BorderRadius.circular(50))
                  ),
                ),
                // Padding(padding: EdgeInsets.all(10)),
                // TextField(
                //   keyboardType: TextInputType.number,
                //   //obscureText: true,
                //   controller: otpControl,
                //   decoration: InputDecoration(
                //     filled: true,
                //     //hintText: "Username",
                //     prefixIcon: Icon(Icons.output),
                //     labelText: "     Type your OTP",
                //     // border: OutlineInputBorder(
                //     //     borderRadius: BorderRadius.circular(50))
                //   ),
                // ),
                Padding(padding: EdgeInsets.all(15)),

                OutlinedButton(
                    onPressed: () async {
                      try {
                        //SignIn();
                        await fauth.signInWithEmailAndPassword(
                            email: nameControl.text.trim(),
                            password: passControl.text.trim());
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => reportPage()));
                        // Fluttertoast.showToast(msg: "Login Success");
                        nameControl.text = "";
                        passControl.text = "";
                      } catch (e) {
                        toastification.show(context: context,autoCloseDuration: Duration(seconds: 5),description: Text('Login Failed! Please check your UserName and Password'));
                        //   Fluttertoast.showToast(
                        //       msg:
                        //           "Login Failed\nPlease check your\nUserName and Password");
                        // }
                        //For Debugging **
                        //Navigator.of(context).push(MaterialPageRoute(builder:   (context) => home_p()));
                      }
                    },
                    style: ButtonStyle(),
                    child: Text("Login")),
                Padding(padding: EdgeInsets.all(50)),
                Text('or Sign Up using'),
                Padding(padding: EdgeInsets.only(top: 10)),
                OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => signUp()));
                    },
                    child: Text("Sign Up"))
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
