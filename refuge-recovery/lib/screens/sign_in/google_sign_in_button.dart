import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:refugerecovery/data/user.dart';
import 'package:refugerecovery/globals.dart' as globals;
import 'package:refugerecovery/screens/home.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback onComplete;

  const GoogleSignInButton({
    Key key,
    this.onComplete,
  }) : super(key: key);

  @override
  _GoogleSignInButtonState createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  User currentUser;

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle() async {
    final postUrl = 'https://refugerecoverydata.azure-api.net/api/users';

    final GoogleSignInAccount acct = await googleSignIn.signIn();
    final GoogleSignInAuthentication auth = await acct.authentication;
    final AuthCredential cred = GoogleAuthProvider.getCredential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    final AuthResult authResult = await firebaseAuth.signInWithCredential(cred);
    final FirebaseUser firebaseUser = authResult.user;

    User user = User(
        userId: '00000000-0000-0000-0000-000000000000',
        authId: firebaseUser.uid,
        authProviderId: '162bf3bc-478c-4c2d-ad19-d3f60fe86537',
        displayName: firebaseUser.displayName,
        email: firebaseUser.email,
        joinDate: DateTime.now());

    var response = await http.post(postUrl,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
          "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
        },
        body: user.toJson());

    globals.currentUser = User.fromJson(json.decode(response.body));
  }

  void signOutGoogle() async {
    await googleSignIn.signOut();
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

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      onPressed: () {
        signInWithGoogle().whenComplete(() {
          showHomeScreen();
        });
      },
      splashColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage("assets/google.png"), height: 35.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
