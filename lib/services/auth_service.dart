import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // Current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Sign Up with Email & Password ───
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    required String department,
    required String university,
    String phone = '',
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Network slow hai. Internet check kro aur dobara try kro.');
      });

      final User? user = credential.user;
      if (user == null) {
        return {'success': false, 'error': 'User creation failed'};
      }

      // Update display name (non-critical, don't block)
      try {
        await user.updateDisplayName(name).timeout(const Duration(seconds: 5));
      } catch (_) {}

      // Generate avatar initials
      final avatar =
          name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

      // Save user data to Firestore (with timeout so it won't hang)
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name.trim(),
          'email': email.trim(),
          'department': department.trim(),
          'university': university,
          'avatar': avatar,
          'role': '',
          'hasSelectedRole': false,
          'walletBalance': 0.0,
          'totalEarned': 0.0,
          'totalWithdrawn': 0.0,
          'totalOrders': 0,
          'totalGigs': 0,
          'rating': 0.0,
          'bio': '',
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 10));
      } catch (firestoreError) {
        // Firestore write failed but user is still created in Auth
        // We'll retry saving data on next login
        debugPrint('Firestore save failed: $firestoreError');
      }

      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password bahut weak hai. Kam az kam 6 characters use kro.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Is email se pehle se account ban chuka hai.';
          break;
        case 'invalid-email':
          errorMessage = 'Email format sahi nahi hai.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/Password sign up abhi enable nahi hai. Firebase Console mein jaake Authentication > Sign-in method > Email/Password enable kro.';
          break;
        default:
          errorMessage = e.message ?? 'Sign up failed. Dobara try kro.';
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Kuch error aayi: ${e.toString()}'};
    }
  }

  // ─── Login with Email & Password ───
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Network slow hai. Internet check kro aur dobara try kro.');
      });

      final User? user = credential.user;
      if (user == null) {
        return {'success': false, 'error': 'Login failed'};
      }

      // Ensure user document exists in Firestore
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get()
            .timeout(const Duration(seconds: 10));
        if (!doc.exists) {
          // User exists in Auth but not in Firestore — create document
          final avatar = (user.displayName ?? 'U')
              .trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? email.trim(),
            'department': '',
            'university': '',
            'avatar': avatar,
            'role': '',
            'hasSelectedRole': false,
            'walletBalance': 0.0,
            'totalEarned': 0.0,
            'totalWithdrawn': 0.0,
            'totalOrders': 0,
            'totalGigs': 0,
            'rating': 0.0,
            'bio': '',
            'phone': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 10));
        }
      } catch (firestoreError) {
        debugPrint('Firestore check/create failed: $firestoreError');
      }

      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Is email se koi account nahi mila.';
          break;
        case 'wrong-password':
          errorMessage = 'Password ghalat hai.';
          break;
        case 'invalid-email':
          errorMessage = 'Email format sahi nahi hai.';
          break;
        case 'user-disabled':
          errorMessage = 'Ye account disable kar diya gaya hai.';
          break;
        case 'invalid-credential':
          errorMessage = 'Email ya password ghalat hai.';
          break;
        default:
          errorMessage = e.message ?? 'Login failed. Dobara try kro.';
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Kuch error aayi: ${e.toString()}'};
    }
  }

  // ─── Get User Data from Firestore ───
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Update User Profile ───
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Sign In with Google ───
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return {'success': false, 'error': 'Sign-in cancel ho gaya.'};
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential)
              .timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Network slow hai. Internet check kro aur dobara try kro.');
      });

      final User? user = userCredential.user;
      if (user == null) {
        return {'success': false, 'error': 'Google sign-in failed'};
      }

      // Check if user document exists in Firestore, create if not
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get()
            .timeout(const Duration(seconds: 10));
        if (!doc.exists) {
          // First time Google sign-in — create Firestore profile
          final name = user.displayName ?? googleUser.displayName ?? '';
          final email = user.email ?? googleUser.email;
          final avatar = name.isNotEmpty
              ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
              : email[0].toUpperCase();

          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
            'email': email,
            'department': '',
            'university': '',
            'avatar': avatar,
            'role': '',
            'hasSelectedRole': false,
            'walletBalance': 0.0,
            'totalEarned': 0.0,
            'totalWithdrawn': 0.0,
            'totalOrders': 0,
            'totalGigs': 0,
            'rating': 0.0,
            'bio': '',
            'phone': '',
            'photoUrl': user.photoURL ?? '',
            'authProvider': 'google',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 10));
        }
      } catch (firestoreError) {
        debugPrint('Firestore check/create failed: $firestoreError');
      }

      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in FirebaseAuth error: ${e.code} - ${e.message}');
      return {'success': false, 'error': e.message ?? 'Google sign-in failed.'};
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return {'success': false, 'error': 'Google sign-in mein error aayi: ${e.toString()}'};
    }
  }

  // ─── Logout (Firebase + Google) ───
  Future<void> logout() async {
    // Sign out from Google (silently disconnect to clear cached account)
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
    } catch (_) {
      // Google sign out failed, continue with Firebase sign out
    }
    await _auth.signOut();
  }

  // ─── Reset Password ───
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Password reset link bhej diya gaya hai $email par.'
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': e.message ?? 'Failed to send reset email'};
    } catch (e) {
      return {'success': false, 'error': 'Kuch error aayi: $e'};
    }
  }
}
