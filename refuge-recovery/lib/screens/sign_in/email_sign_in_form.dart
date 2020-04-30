import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:refugerecovery/data/user.dart';
import 'package:refugerecovery/globals.dart' as globals;

import '../home.dart';

class EmailSignInForm extends StatefulWidget {
  final VoidCallback onComplete;

  const EmailSignInForm({
    Key key,
    this.onComplete,
  }) : super(key: key);

  @override
  _EmailSignInFormState createState() => _EmailSignInFormState();
}

class _EmailSignInFormState extends State<EmailSignInForm> {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _authenticateUser() async {
    AuthResult authResult;
    FirebaseUser firebaseUser;

    final postUrl = 'https://refugerecoverydata.azure-api.net/api/users';

    final form = _formKey.currentState;
    if (form.validate() == false) {
      return;
    }
    final email = emailController.text.trim();
    final password = passwordController.text;
    try {
      authResult = await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } on PlatformException catch (e) {
      if (e.code == 'ERROR_USER_NOT_FOUND') {
        authResult = await firebaseAuth.createUserWithEmailAndPassword(
            email: email, password: password);
      } else if (e.code == 'PASSWORD_NOT_CORRECT') {
        return;
      }
    } on Exception catch (e) {
      print(e.toString());
      return;
    }
    firebaseUser = authResult.user;

    User user = User(
        userId: '00000000-0000-0000-0000-000000000000',
        authId: firebaseUser.uid,
        authProviderId: 'a37c85a0-bec2-4a03-827b-548038a491fe',
        displayName: firebaseUser.email,
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

    showHomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    var passwordFocusNode = FocusNode();
    var signinFocusNode = FocusNode();

    return Container(
        margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 40.0),
        child: Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                decoration: InputDecoration(
                    labelText: 'Enter email',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.grey, width: 1.0))),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(passwordFocusNode);
                },
                style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 18.0),
                controller: emailController,
                validator: (String text) {
                  if (text.isEmpty) {
                    return "Email is empty";
                  } else {
                    return null;
                  }
                },
              ),
              SizedBox(height: 5.0),
              TextFormField(
                decoration: InputDecoration(
                    labelText: 'Enter password',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.grey, width: 1.0))),
                obscureText: true,
                focusNode: passwordFocusNode,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(signinFocusNode);
                },
                style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 18.0),
                controller: passwordController,
                validator: (text) {
                  if (text.isEmpty) {
                    return "Password is empty";
                  } else {
                    return null;
                  }
                },
              ),
              SizedBox(height: 5.0),
              FlatButton(
                focusNode: signinFocusNode,
                child: Text('Sign in'),
                color: Colors.grey,
                focusColor: Color.fromRGBO(165, 132, 41, 1),
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                onPressed: _authenticateUser,
              )
            ])));
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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
