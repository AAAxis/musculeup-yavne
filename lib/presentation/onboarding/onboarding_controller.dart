import 'package:firebase_auth/firebase_auth.dart';

class OnboardingController {
  final User firebaseUser;

  // Personal info
  String name;
  String? gender;
  DateTime? birthDate;
  
  // Physical info
  double? height;
  double? initialWeight;
  
  // Coach info
  String? coachName;
  String? coachEmail;
  String? coachPhone;
  
  // Contract info
  String? contractFullName;
  String? contractSignatureBase64; // Store base64 temporarily
  String? contractSignatureUrl; // Will be set after upload

  OnboardingController({
    required this.firebaseUser,
  }) : name = firebaseUser.displayName ?? '';

  bool get isComplete {
    return name.isNotEmpty &&
        // gender is now optional
        // birthDate is now optional  
        height != null &&
        initialWeight != null &&
        coachName != null &&
        coachEmail != null &&
        contractFullName != null &&
        contractSignatureBase64 != null;
  }
}

