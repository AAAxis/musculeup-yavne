import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String email;
  final String name;
  final String? photoUrl;
  final String? gender;
  final String? birthDate;
  final double? height;
  final double? initialWeight;
  final String? coachName;
  final String? coachEmail;
  final String? coachPhone;
  final String? role;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  UserModel({
    required this.email,
    required this.name,
    this.photoUrl,
    this.gender,
    this.birthDate,
    this.height,
    this.initialWeight,
    this.coachName,
    this.coachEmail,
    this.coachPhone,
    this.role,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  // Check if profile is complete
  bool get isProfileComplete {
    return name.isNotEmpty &&
        gender != null &&
        birthDate != null &&
        height != null &&
        initialWeight != null &&
        coachName != null &&
        coachEmail != null;
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birth_date': birthDate,
      if (height != null) 'height': height,
      if (initialWeight != null) 'initial_weight': initialWeight,
      if (coachName != null) 'coach_name': coachName,
      if (coachEmail != null) 'coach_email': coachEmail,
      if (coachPhone != null) 'coach_phone': coachPhone,
      'role': role ?? 'user',
      'status': status ?? 'active',
      'updated_at': FieldValue.serverTimestamp(),
      'last_login': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photo_url'],
      gender: data['gender'],
      birthDate: data['birth_date'],
      height: data['height']?.toDouble(),
      initialWeight: data['initial_weight']?.toDouble(),
      coachName: data['coach_name'],
      coachEmail: data['coach_email'],
      coachPhone: data['coach_phone'],
      role: data['role'],
      status: data['status'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      lastLogin: (data['last_login'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with method
  UserModel copyWith({
    String? email,
    String? name,
    String? photoUrl,
    String? gender,
    String? birthDate,
    double? height,
    double? initialWeight,
    String? coachName,
    String? coachEmail,
    String? coachPhone,
    String? role,
    String? status,
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      initialWeight: initialWeight ?? this.initialWeight,
      coachName: coachName ?? this.coachName,
      coachEmail: coachEmail ?? this.coachEmail,
      coachPhone: coachPhone ?? this.coachPhone,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLogin: lastLogin,
    );
  }
}

