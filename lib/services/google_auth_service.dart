import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn =
    GoogleSignIn(
      serverClientId:
        '186525492799-9gsu1ljpejodafcbu717tu0h1lgg85ie'
        '.apps.googleusercontent.com',
      scopes: const ['email', 'profile'],
    );

  static Future<Map<String, dynamic>?>
      signIn() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account =
        await _googleSignIn.signIn();

      if (account == null) return null;

      final GoogleSignInAuthentication auth =
        await account.authentication;

      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception(
          'Could not get ID token from Google');
      }

      final api = ApiService();
      final response =
        await api.googleSignIn(idToken);

      return response;

    } catch (e) {
      throw Exception(
        'Google Sign-In failed: $e');
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}