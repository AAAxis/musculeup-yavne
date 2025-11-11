import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/presentation/onboarding/screens/name_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/gender_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/birthdate_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/height_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/weight_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/coach_name_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/coach_email_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/coach_phone_screen.dart';
import 'package:muscleup/presentation/onboarding/screens/complete_screen.dart';

class OnboardingFlow extends StatefulWidget {
  final User firebaseUser;

  const OnboardingFlow({super.key, required this.firebaseUser});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late PageController _pageController;
  late OnboardingController _controller;
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

  void _nextPage() {
    if (_currentPage < 8) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          NameScreen(
            controller: _controller,
            onNext: _nextPage,
          ),
          GenderScreen(
            controller: _controller,
            onNext: _nextPage,
            onBack: _previousPage,
          ),
          BirthdateScreen(
            controller: _controller,
            onNext: _nextPage,
            onBack: _previousPage,
          ),
          HeightScreen(
            controller: _controller,
            onNext: _nextPage,
            onBack: _previousPage,
          ),
          WeightScreen(
            controller: _controller,
            onNext: _nextPage,
            onBack: _previousPage,
          ),
          CoachNameScreen(
            controller: _controller,
            onNext: _nextPage,
            onBack: _previousPage,
          ),
          CoachEmailScreen(
            controller: _controller,
            onNext: _nextPage,
            onBack: _previousPage,
          ),
          CoachPhoneScreen(
            controller: _controller,
            onNext: _nextPage,
            onBack: _previousPage,
          ),
          CompleteScreen(
            controller: _controller,
            onBack: _previousPage,
          ),
        ],
      ),
    );
  }
}

