import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb 
        ? '819875755268-bmth1hm5v3hj4v6usbm6aqa6tap7oh5r.apps.googleusercontent.com'
        : null,

    serverClientId: kIsWeb ? null : '819875755268-bmth1hm5v3hj4v6usbm6aqa6tap7oh5r.apps.googleusercontent.com',
  );

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }


      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      final response = await http.post(
        Uri.parse('${_apiBaseUrl()}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final Map<String, dynamic> payload = 
          (response.body.isNotEmpty 
              ? (jsonDecode(response.body) as Map<String, dynamic>) 
              : <String, dynamic>{});

      if (response.statusCode == 200 && payload['ok'] == true) {
        return payload['user'] as Map<String, dynamic>?;
      } else {
        throw Exception(payload['message'] ?? 'Google sign-in failed');
      }
    } catch (error) {
      print('Google Sign-In Error: $error');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
