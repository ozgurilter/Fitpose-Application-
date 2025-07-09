import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_tracking_app/models/userModel.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserData(String uid) async {
    setLoading(true);
    _errorMessage = null;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        _currentUser = UserModel.fromJson(docSnapshot.data()!);
        notifyListeners();
      } else {
        _errorMessage = 'Kullanıcı verileri bulunamadı';
      }
    } catch (e) {
      _errorMessage = 'Kullanıcı verileri alınırken hata oluştu: ${e.toString()}';
      debugPrint('Error fetching user data: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateUserInfo({
    required String uid,
    String? nameSurname,
    double? height,
    double? weight,
    String? newPassword,
    String? currentPassword,
  }) async {
    setLoading(true);
    _errorMessage = null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // Handle password change
      if (newPassword != null && newPassword.isNotEmpty) {
        if (currentPassword == null || currentPassword.isEmpty) {
          throw Exception('Şifre değişikliği için mevcut şifre gereklidir');
        }
        await _reauthenticate(user.email!, currentPassword);
        await user.updatePassword(newPassword);
      }

      // Prepare Firestore update
      final updateData = <String, dynamic>{};
      if (nameSurname != null) updateData['nameSurname'] = nameSurname;
      if (height != null) updateData['height'] = height;
      if (weight != null) updateData['weight'] = weight;

      if (updateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updateData);

        // Update local state
        _currentUser = _currentUser?.copyWith(
          nameSurname: nameSurname ?? _currentUser?.nameSurname,
          height: height ?? _currentUser?.height,
          weight: weight ?? _currentUser?.weight,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Profil güncellenirken hata oluştu: ${e.toString()}';
      debugPrint('Update user error: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> _reauthenticate(String email, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      debugPrint('Reauthentication error: $e');
      throw Exception('Şifre doğrulanamadı: ${e.toString()}');
    }
  }

  Future<void> logout() async {

    _currentUser = null;
    notifyListeners();

  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearUserData() {
    _currentUser = null;
    notifyListeners();
  }
}