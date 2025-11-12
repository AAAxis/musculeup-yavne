import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';

class CoachInfoScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CoachInfoScreen({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<CoachInfoScreen> createState() => _CoachInfoScreenState();
}

class _CoachInfoScreenState extends State<CoachInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coachNameController = TextEditingController();
  final _coachEmailController = TextEditingController();
  final _coachPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _coachNameController.text = widget.controller.coachName ?? '';
    _coachEmailController.text = widget.controller.coachEmail ?? '';
    _coachPhoneController.text = widget.controller.coachPhone ?? '';
  }

  @override
  void dispose() {
    _coachNameController.dispose();
    _coachEmailController.dispose();
    _coachPhoneController.dispose();
    super.dispose();
  }

  void _handleNext() {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    
    // Wait a bit for keyboard to dismiss, then validate
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_formKey.currentState!.validate()) {
        widget.controller.coachName = _coachNameController.text.trim();
        widget.controller.coachEmail = _coachEmailController.text.trim();
        widget.controller.coachPhone = _coachPhoneController.text.trim().isEmpty
            ? null
            : _coachPhoneController.text.trim();
        widget.onNext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('מידע על המאמן'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Progress Indicator
                LinearProgressIndicator(
                  value: 3 / 4, // Step 3 of 4
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'פרטי המאמן שלך',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'מי ילווה אותך במסע הכושר שלך?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 32),

              // Coach Name Field
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _coachNameController,
                  decoration: InputDecoration(
                    labelText: 'שם המאמן *',
                    hintText: 'הזן את שם המאמן שלך',
                    prefixIcon: const Icon(Icons.person_pin),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'אנא הזן את שם המאמן';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Coach Email Field
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _coachEmailController,
                  decoration: InputDecoration(
                    labelText: 'אימייל המאמן *',
                    hintText: 'coach@example.com',
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'אנא הזן את אימייל המאמן';
                    }
                    if (!value.contains('@')) {
                      return 'אנא הזן אימייל תקין';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Coach Phone Field (Optional)
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _coachPhoneController,
                  decoration: InputDecoration(
                    labelText: 'טלפון המאמן',
                    hintText: 'אופציונלי',
                    prefixIcon: const Icon(Icons.phone),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: 48),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'המשך',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

