import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:refugerecovery/data/user.dart';

import 'globals.dart' as globals;

User currentUser;

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<void> signInWithGoogle() async {
  final postUrl = 'https://refugerecoverydata.azurewebsites.net/api/users';

  final GoogleSignInAccount acct = await googleSignIn.signIn();
  final GoogleSignInAuthentication auth = await acct.authentication;
  final AuthCredential cred = GoogleAuthProvider.getCredential(
    accessToken: auth.accessToken,
    idToken: auth.idToken,
  );

  final AuthResult authResult = await firebaseAuth.signInWithCredential(cred);
  final FirebaseUser firebaseUser = authResult.user;

  globals.currentUser = User(
      userId: firebaseUser.uid,
      displayName: firebaseUser.displayName,
      email: firebaseUser.email,
      joinDate: DateTime.now());

  await http.post(postUrl,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: globals.currentUser.toJson());
}

void signOutGoogle() async {
  await googleSignIn.signOut();
}
