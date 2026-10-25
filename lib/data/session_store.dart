import 'dart:typed_data';
import 'package:flutter/material.dart';

enum UserRole { owner, karyawan }

class AppUser {
  String name;
  String identifier; // email atau nomor HP yang dipakai masuk
  UserRole role;
  Uint8List? photo;

  AppUser({
    required this.name,
    required this.identifier,
    this.role = UserRole.owner,
    this.photo,
  });

  bool get isOwner => role == UserRole.owner;
  String get roleLabel => isOwner ? 'Pemilik UMKM' : 'Karyawan';
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}

class BusinessInfo {
  String name;
  String address;
  String phone;
  String receiptNote; // tulisan di bagian bawah struk

  BusinessInfo({
    this.name = 'Usaha Saya',
    this.address = '',
    this.phone = '',
    this.receiptNote = '',
  });
}

/// Akun yang sedang masuk + data usaha. Nanti diisi dari backend/database.
class SessionStore extends ChangeNotifier {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  final AppUser _demo = AppUser(name: 'Mr. Kumar', identifier: '');
  AppUser? user;
  AppUser? _registered;
  final BusinessInfo business = BusinessInfo();

  /// Akun aktif (kalau belum ada, dipakai akun contoh).
  AppUser get current => user ??= _demo;

  void signIn(String identifier) {
    final r = _registered;
    if (r != null && r.identifier == identifier) {
      user = r;
    } else {
      _demo.identifier = identifier;
      user = _demo;
    }
    notifyListeners();
  }

  void register({
    required String name,
    required String businessName,
    required String identifier,
  }) {
    _registered = AppUser(name: name, identifier: identifier);
    business.name = businessName;
    notifyListeners();
  }

  void signOut() {
    user = null;
    notifyListeners();
  }

  void setPhoto(Uint8List? bytes) {
    current.photo = bytes;
    notifyListeners();
  }

  void updateBusiness({
    required String name,
    required String address,
    required String phone,
    required String receiptNote,
  }) {
    business
      ..name = name
      ..address = address
      ..phone = phone
      ..receiptNote = receiptNote;
    notifyListeners();
  }
}
