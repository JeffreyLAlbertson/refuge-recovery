import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:refugerecovery/screens/home.dart';
import 'package:refugerecovery/screens/sign_in/email_sign_in_form.dart';
import 'package:refugerecovery/screens/sign_in/facebook_sign_in_button.dart';
import 'package:refugerecovery/screens/sign_in/google_sign_in_button.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      color: Colors.white,
      child: Center(
        child: ListView(shrinkWrap: true, children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GoogleSignInButton(),
              SizedBox(height: 5.0),
              FacebookSignInButton(),
              Text("or",
                  style:
                      TextStyle(fontFamily: 'HelveticaNeue', fontSize: 20.0)),
              EmailSignInForm(),
            ],
          ),
        ]),
      ),
    ));
  }

  void showHomeScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) {
          return HomeScreen(0);
        },
      ),
      (_) => false,
    );
  }
}
