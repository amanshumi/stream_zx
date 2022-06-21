import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signin.dart';
import 'home.dart';
import 'package:connectivity/connectivity.dart';

class Landing extends StatelessWidget {
  const Landing({Key? key}) : super(key: key);

  void isUserAuth(c) async {
    var prefs = await SharedPreferences.getInstance();

    var connectivityResult = await (Connectivity().checkConnectivity());

    String? email = prefs.getString("email");

    if (email == null) {
      return;
    }

    if (email.length > 0 && connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      Navigator.push(c, MaterialPageRoute(builder: (context) => Home()));
    } else {
      ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(content: Text("Please connect to the internet")));
    }
  }

  @override
  Widget build(BuildContext context) {
    isUserAuth(context);

    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
            padding: EdgeInsets.only(top: 30),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: 80),
                  Container(
                    child: Image(
                        image: AssetImage("assets/landing_illustration.png")),
                  ),
                  SizedBox(height: 30),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      child: Text("Stream ZX",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontFamily: "Montserrat",
                              fontSize: 20,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800]))),
                  SizedBox(height: 20),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      child: Text("Personalized music streaming in your pocket",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontFamily: "Montserrat",
                              fontSize: 29,
                              letterSpacing: 1.5,
                              height: 1.6,
                              fontWeight: FontWeight.bold,
                              color: Colors.black))),
                  SizedBox(height: 20),
                  Container(
                      margin: EdgeInsets.only(right: 40),
                      width: MediaQuery.of(context).size.width,
                      child: Text(
                          "We stream music from the internet to your device, so you can listen continuously, even when minimized.",
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                              fontFamily: "Montserrat",
                              fontSize: 14,
                              letterSpacing: 1.5,
                              height: 1.6,
                              color: Colors.black))),
                  SizedBox(height: 30),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 50,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(100)),
                    padding: EdgeInsets.all(0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(48.0),
                      ))),
                      child: Text("get started",
                          style: TextStyle(
                              fontFamily: "Montserrat",
                              fontSize: 14,
                              letterSpacing: 1.5,
                              height: 1.6,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      onPressed: () async {
                        var connectivityResult =
                            await (Connectivity().checkConnectivity());
                        if (connectivityResult == ConnectivityResult.mobile ||
                            connectivityResult == ConnectivityResult.wifi) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Signin()));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Please connect to the internet")));
                        }
                      },
                    ),
                  ),
                ],
              ),
            )));
  }
}
