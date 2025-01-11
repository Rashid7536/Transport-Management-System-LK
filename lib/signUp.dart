import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:leaflet_test/database.dart';
import 'package:leaflet_test/login_page.dart';
import 'package:toastification/toastification.dart';

class signUp extends StatefulWidget {
  const signUp({super.key});

  @override
  State<signUp> createState() => _signUpState();
}

class _signUpState extends State<signUp> {
  final fdb = FirebaseDatabase.instance;
  final dataB = Database_mthds();
  final fauth = FirebaseAuth.instance;
  final nameControl = TextEditingController();
  final eControl = TextEditingController();
  final passControl = TextEditingController();
  final passConfControl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //backgroundColor: Colors.blueGrey[200],
        appBar: AppBar(),
        body: Center(
          child: SizedBox(
            width: 250,
            height: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  Padding(padding: EdgeInsets.all(10)),
                  TextField(
                    controller: nameControl,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.account_circle),
                      filled: true,
                      //fillColor: Colors.white,
                      //hintText: "Username",
                      labelText: "     First Name",
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(10)),
                  TextField(
                    controller: eControl,
                    decoration: InputDecoration(
                      filled: true,
                      prefixIcon: Icon(Icons.email),
                      //fillColor: Colors.white,
                      //hintText: "Username",
                      labelText: "     Email",
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(10)),
                  TextField(
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    controller: passControl,
                    decoration: InputDecoration(
                      filled: true,
                      prefixIcon: Icon(Icons.password),
                      //hintText: "Username",
                      labelText: "     Password",
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(10)),
                  TextField(
                    keyboardType: TextInputType.visiblePassword,
                    controller: passConfControl,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      //hintText: "Username",
                      prefixIcon: Icon(Icons.password),
                      labelText: "     Confirm Password",
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(30)),
                  Text('Sign Up with'),
                  Padding(padding: EdgeInsets.all(5)),
                  OutlinedButton(
                      onPressed: () async {
                        if (passControl.text == passConfControl.text) {
                          try {
                            //SignIn();
                            await fauth.createUserWithEmailAndPassword(
                                email: eControl.text.trim(),
                                password: passControl.text.trim());
                            await fauth.signInWithEmailAndPassword(
                                email: 'registrar@transit.com',
                                password: 'transit123');
                            dataB.addUser(nameControl.text,
                                eControl.text.toLowerCase().trim());
                            await fauth.signOut();

                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => login_p()));
                            toastification.show(
                                context: context,
                                autoCloseDuration: Duration(seconds: 5),
                                description: Text(
                                    'Sign up success!'));
                            eControl.text = "";
                            passControl.text = "";
                            passConfControl.text = "";
                          } on FirebaseAuthException catch (e) {
                            toastification.show(
                                context: context,
                                autoCloseDuration: Duration(seconds: 5),
                                description: Text(
                                    e.toString()+'Sign up failed!'));
                          }
                        } else {
                          toastification.show(
                              context: context,
                              autoCloseDuration: Duration(seconds: 5),
                              description: Text(
                                  'Passwords should match!'));
                        }
                      },
                      child: Text("Sign Up")),
                  Padding(padding: EdgeInsets.all(10)),
                ],
              ),
            ),
          ),
        ));
  }
}
