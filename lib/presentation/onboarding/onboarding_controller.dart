import 'package:firebase_auth/firebase_auth.dart';

class OnboardingData {
  String? name;
  String? gender;
  DateTime? birthDate;
  double? height;
  double? weight;
  String? coachName;
  String? coachEmail;
  String? coachPhone;

  OnboardingData({
    this.name,
    this.gender,
    this.birthDate,
    this.height,
    this.weight,
    this.coachName,
    this.coachEmail,
    this.coachPhone,
  });
}

class OnboardingController {
  final User firebaseUser;
  final OnboardingData data;

  OnboardingController({
    required this.firebaseUser,
  }) : data = OnboardingData(name: firebaseUser.displayName);

  bool get isComplete {
    return data.name != null &&
        data.gender != null &&
        data.birthDate != null &&
        data.height != null &&
        data.weight != null &&
        data.coachName != null &&
        data.coachEmail != null;
  }
}

