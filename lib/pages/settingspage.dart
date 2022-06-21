import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_zx/pages/signin.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? name;
  String? email;
  String? phone;
  String? avatar;
  String? uid;

  void signUserOut(ctx) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("email");
    prefs.remove("name");
    prefs.remove("avatar");
    prefs.remove("phone");
    prefs.remove("uid");
    prefs.clear();

    Navigator.push(ctx, MaterialPageRoute(builder: (context) => Signin()));
  }

  void loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString("name");
      email = prefs.getString("email");
      avatar = prefs.getString("avatar");
      uid = prefs.getString("uid");
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    loadUser();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      children: [
        Stack(
          children: [
            Container(
              height: 180,
              color: Colors.black,
            ),
            Center(
                child: Container(
                    margin: EdgeInsets.only(top: 110),
                    height: 130,
                    width: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      image: DecorationImage(
                          fit: BoxFit.cover, image: NetworkImage("${avatar}")),
                    ))),
            Center(
                child: Container(
              margin: EdgeInsets.only(top: 50),
              child: Text(
                "${name}",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 35,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ))
          ],
        ),
        SizedBox(height: 40),
        Container(
            margin: EdgeInsets.only(bottom: 15),
            width: MediaQuery.of(context).size.width * 0.94,
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                  offset: Offset(5, 3),
                  blurRadius: 10,
                  color: Colors.grey.shade200)
            ], color: Colors.white, borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.email),
                SizedBox(width: 20),
                Text(
                  "${email}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.normal),
                )
              ],
            )),
        Container(
            margin: EdgeInsets.only(bottom: 15),
            width: MediaQuery.of(context).size.width * 0.94,
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                  offset: Offset(5, 3),
                  blurRadius: 10,
                  color: Colors.grey.shade200)
            ], color: Colors.white, borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.location_on),
                SizedBox(width: 20),
                Text(
                  "${uid}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                  ),
                )
              ],
            )),
        Container(
            margin: EdgeInsets.only(bottom: 15),
            width: MediaQuery.of(context).size.width * 0.94,
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                  offset: Offset(5, 3),
                  blurRadius: 10,
                  color: Colors.grey.shade200)
            ], color: Colors.white, borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.calendar_today),
                SizedBox(width: 20),
                Text(
                  "March 18, 1999",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.normal),
                )
              ],
            )),
        Container(
            margin: EdgeInsets.only(bottom: 15),
            width: MediaQuery.of(context).size.width * 0.94,
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                  offset: Offset(5, 3),
                  blurRadius: 10,
                  color: Colors.grey.shade200)
            ], color: Colors.white, borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: 20),
                Text(
                  "Male",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.normal),
                )
              ],
            )),
        SizedBox(height: 5),
        // Container(
        //     margin: EdgeInsets.only(bottom: 15),
        //     width: MediaQuery.of(context).size.width * 0.7,
        //     decoration: BoxDecoration(
        //       borderRadius: BorderRadius.circular(10),
        //     ),
        //     child: ElevatedButton(
        //         style: ButtonStyle(
        //             shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        //                 RoundedRectangleBorder(
        //               borderRadius: BorderRadius.circular(50),
        //             )),
        //             padding: MaterialStateProperty.all<EdgeInsets>(
        //                 EdgeInsets.all(10))),
        //         onPressed: () {
        //           signUserOut(context);
        //         },
        //         child: Container(
        //             child: Row(
        //           children: [
        //             Icon(Icons.exit_to_app, color: Colors.white),
        //             SizedBox(width: 20),
        //             Text("Logout")
        //           ],
        //         )))),
      ],
    ));
  }
}
