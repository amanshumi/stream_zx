import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Signin extends StatefulWidget {
  const Signin({Key? key}) : super(key: key);

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['https://www.googleapis.com/auth/youtube.upload']);

  Future<FirebaseUser> signInWithGoogle() async {
    GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();

    GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    AuthResult authResult = await _auth.signInWithCredential(credential);

    FirebaseUser currentUser = await _auth.currentUser();

    final prefs = await SharedPreferences.getInstance();

    prefs.setString("email", authResult.user.email);
    prefs.setString("name", authResult.user.displayName);
    prefs.setString("avatar", authResult.user.photoUrl);

    prefs.setString("uid", authResult.user.uid);

    print(googleSignInAuthentication.accessToken);

    return currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 70),
                  Icon(Icons.account_circle_rounded,
                      size: 120, color: Colors.blue[800]),
                  SizedBox(height: 30),
                  Container(
                      child: Text("Sign In",
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                              fontFamily: "Montserrat",
                              fontSize: 24,
                              letterSpacing: 1.5,
                              height: 1.6,
                              fontWeight: FontWeight.bold,
                              color: Colors.black))),
                  SizedBox(height: 30),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 50,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(100)),
                    padding: EdgeInsets.all(0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.grey[50]),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(0.0)),
                              child: Image(
                                height: 30,
                                image: AssetImage("assets/google.jpg"),
                              )),
                          SizedBox(width: 10),
                          Text("Signin with google",
                              style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                  height: 1.6,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                        ],
                      ),
                      onPressed: () async {
                        signInWithGoogle().then((FirebaseUser user) => {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Home()))
                            });
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 50,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(100)),
                    padding: EdgeInsets.all(0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue[900]),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(0.0)),
                              child: Image(
                                height: 30,
                                image: AssetImage("assets/facebook.png"),
                              )),
                          SizedBox(width: 10),
                          Text("Signin with facebook",
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 14,
                                letterSpacing: 1.5,
                                height: 1.6,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )),
                        ],
                      ),
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 50,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(100)),
                    padding: EdgeInsets.all(0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.grey[800]),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(0.0)),
                              child: Image(
                                height: 30,
                                image: AssetImage("assets/twitter.png"),
                              )),
                          SizedBox(width: 10),
                          Text("Signin with twitter",
                              style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                  height: 1.6,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}

mixin SignInViewModel {}
