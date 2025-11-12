import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/presentation/onboarding/screens/welcome_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/personal_info_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/physical_info_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/coach_info_screen.dart';
import 'package:muscleup/presentation/onboarding/contract_screen.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:muscleup/data/services/firestore_service.dart';

class OnboardingFlow extends StatefulWidget {
  final User firebaseUser;

  const OnboardingFlow({super.key, required this.firebaseUser});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late PageController _pageController;
  late OnboardingController _controller;
  final _firestoreService = FirestoreService();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _controller = OnboardingController(firebaseUser: widget.firebaseUser);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    // If moving from coach info to contract, create user first
    if (_currentPage == 3) {
      await _createUser();
    }

    if (_currentPage < 4) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createUser() async {
    try {
      // Create user with pending status (before contract)
      final user = UserModel(
        email: widget.firebaseUser.email!,
        name: _controller.name,
        photoUrl: widget.firebaseUser.photoURL,
        gender: _controller.gender!,
        birthDate: _formatDate(_controller.birthDate!),
        height: _controller.height!,
        initialWeight: _controller.initialWeight!,
        coachName: _controller.coachName!,
        coachEmail: _controller.coachEmail!,
        coachPhone: _controller.coachPhone,
        role: 'user',
        status: 'pending', // Pending until contract is signed
      );

      await _firestoreService.setUser(
        widget.firebaseUser.uid,
        user,
        isNewUser: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת הפרופיל: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleContractSigned(
      String fullName, String signatureUrl) async {
    // Update existing user with contract data and activate
    try {
      await _firestoreService.updateUser(
        widget.firebaseUser.uid,
        {
          'contract_full_name': fullName,
          'contract_signature_url': signatureUrl,
          'contract_signed_at': DateTime.now(),
          'contract_commitments': ['אני מתחייב לעמוד בתנאי החוזה'],
          'hasSignedContract': true,
        },
      );

      // Navigate directly to main app
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בחתימה על החוזה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Step 0: Welcome Screen
          WelcomeScreen(
            userName: widget.firebaseUser.displayName ?? '',
            onStart: _nextPage,
          ),

          // Step 1: Personal Info (Name, Gender, Birth Date) - 3 questions
          PersonalInfoScreen(
            controller: _controller,
            onNext: _nextPage,
          ),

          // Step 2: Physical Info (Height, Weight) - 2 questions
          PhysicalInfoScreen(
            controller: _controller,
            onNext: _nextPage,
            onBack: _previousPage,
          ),

          // Step 3: Coach Info (Coach Name, Email, Phone) - 3 questions
          // Creates user with 'pending' status after this step
          CoachInfoScreen(
            controller: _controller,
            onNext: _nextPage,
            onBack: _previousPage,
          ),

          // Step 4: Contract Signing (updates user to 'active' status)
          ContractScreen(
            userGender: _controller.gender ?? 'male',
            userName: _controller.name,
            userId: widget.firebaseUser.uid,
            onContractSigned: _handleContractSigned,
          ),
        ],
      ),
    );
  }
}
