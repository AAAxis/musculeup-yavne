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
  final bool? notificationsEnabled;
  final bool? emailNotifications;
  final bool? pushNotifications;
  final String? contractFullName;
  final String? contractSignatureBase64; // Temporary base64 storage
  final String? contractSignatureUrl;
  final List<String>? contractCommitments;
  final DateTime? contractSignedAt;

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
    this.notificationsEnabled,
    this.emailNotifications,
    this.pushNotifications,
    this.contractFullName,
    this.contractSignatureBase64,
    this.contractSignatureUrl,
    this.contractCommitments,
    this.contractSignedAt,
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

  // Check if contract is signed (either has base64 or URL)
  bool get hasSignedContract {
    return contractFullName != null &&
        (contractSignatureBase64 != null || contractSignatureUrl != null) &&
        contractCommitments != null &&
        contractSignedAt != null;
  }

  // Check if signature needs to be uploaded
  bool get needsSignatureUpload {
    return contractSignatureBase64 != null && contractSignatureUrl == null;
  }

  // Check if user is active (has signed contract)
  bool get isActive {
    return status == 'active' && hasSignedContract;
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
      'notifications_enabled': notificationsEnabled ?? true,
      'email_notifications': emailNotifications ?? true,
      'push_notifications': pushNotifications ?? true,
      if (contractFullName != null) 'contract_full_name': contractFullName,
      if (contractSignatureBase64 != null) 'contract_signature_base64': contractSignatureBase64,
      if (contractSignatureUrl != null) 'contract_signature_url': contractSignatureUrl,
      if (contractCommitments != null) 'contract_commitments': contractCommitments,
      if (contractSignedAt != null) 'contract_signed_at': Timestamp.fromDate(contractSignedAt!),
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
      notificationsEnabled: data['notifications_enabled'] as bool?,
      emailNotifications: data['email_notifications'] as bool?,
      pushNotifications: data['push_notifications'] as bool?,
      contractFullName: data['contract_full_name'],
      contractSignatureBase64: data['contract_signature_base64'],
      contractSignatureUrl: data['contract_signature_url'],
      contractCommitments: (data['contract_commitments'] as List<dynamic>?)?.cast<String>(),
      contractSignedAt: (data['contract_signed_at'] as Timestamp?)?.toDate(),
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
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    String? contractFullName,
    String? contractSignatureBase64,
    String? contractSignatureUrl,
    List<String>? contractCommitments,
    DateTime? contractSignedAt,
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
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      contractFullName: contractFullName ?? this.contractFullName,
      contractSignatureBase64: contractSignatureBase64 ?? this.contractSignatureBase64,
      contractSignatureUrl: contractSignatureUrl ?? this.contractSignatureUrl,
      contractCommitments: contractCommitments ?? this.contractCommitments,
      contractSignedAt: contractSignedAt ?? this.contractSignedAt,
    );
  }
}

