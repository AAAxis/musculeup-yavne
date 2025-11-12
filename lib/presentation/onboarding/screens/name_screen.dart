import 'package:flutter/material.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/presentation/onboarding/widgets/onboarding_base.dart';

class NameScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;

  const NameScreen({
    super.key,
    required this.controller,
    required this.onNext,
  });

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.controller.name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_nameController.text.trim().isNotEmpty) {
      widget.controller.name = _nameController.text.trim();
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBase(
      currentStep: 1,
      totalSteps: 8,
      title: 'What\'s your name?',
      subtitle: 'Let\'s start with the basics',
      onNext: _handleNext,
      isNextEnabled: _nameController.text.trim().isNotEmpty,
      child: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Full Name',
          hintText: 'Enter your full name',
          prefixIcon: Icon(Icons.person),
        ),
        textCapitalization: TextCapitalization.words,
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (_) => _handleNext(),
      ),
    );
  }
}
