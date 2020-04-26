import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:http/http.dart' as http;
import 'package:refugerecovery/data/user.dart';
import 'package:refugerecovery/globals.dart' as globals;
import 'package:refugerecovery/screens/home.dart';

class FacebookSignInButton extends StatefulWidget {
  final VoidCallback onComplete;

  const FacebookSignInButton({
    Key key,
    this.onComplete,
  }) : super(key: key);

  @override
  _FacebookSignInButtonState createState() => _FacebookSignInButtonState();
}

class _FacebookSignInButtonState extends State<FacebookSignInButton> {
  Future<void> _createUser(AuthResult authResult) async {
    final postUrl = 'https://refugerecoverydata.azure-api.net/api/users';

    final firebaseUser = authResult.user;

    User user = User(
        userId: '00000000-0000-0000-0000-000000000000',
        authId: firebaseUser.uid,
        authProviderId: '91fdea1d-1821-47eb-8789-961c05fb5ab7',
        displayName: firebaseUser.displayName,
        email: firebaseUser.email,
        joinDate: DateTime.now());

    var response = await http.post(postUrl,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
          "Ocp-Apim-Subscription-Key": "570fd8d1df544dc4b3fe4dcb16f631ac"
        },
        body: user.toJson());

    globals.currentUser = User.fromJson(json.decode(response.body));
  }

  Future<void> _authenticateUser() async {
    final facebookLogin = FacebookLogin();
    final result = await facebookLogin.logIn(['email']);

    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        final authCredential = FacebookAuthProvider.getCredential(
            accessToken: result.accessToken.token);
        final authResult =
            await FirebaseAuth.instance.signInWithCredential(authCredential);
        await _createUser(authResult);
        showHomeScreen();
        break;
      case FacebookLoginStatus.cancelledByUser:
        break;
      case FacebookLoginStatus.error:
        break;
    }
  }

  Widget build(BuildContext context) {
    return OutlineButton(
      onPressed: _authenticateUser,
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
            Image(image: AssetImage("assets/facebook.png"), height: 35.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Facebook',
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
