import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  UserModel? _currentUser;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _coachNameController;
  late TextEditingController _coachEmailController;
  late TextEditingController _coachPhoneController;

  String? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _coachNameController = TextEditingController();
    _coachEmailController = TextEditingController();
    _coachPhoneController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _coachNameController.dispose();
    _coachEmailController.dispose();
    _coachPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      try {
        final user = await _firestoreService.getUser(authState.user.uid);
        if (user != null && mounted) {
          setState(() {
            _currentUser = user;
            _nameController.text = user.name;
            _heightController.text = user.height?.toString() ?? '';
            _weightController.text = user.initialWeight?.toString() ?? '';
            _coachNameController.text = user.coachName ?? '';
            _coachEmailController.text = user.coachEmail ?? '';
            _coachPhoneController.text = user.coachPhone ?? '';
            _selectedGender = user.gender != null 
                ? user.gender![0].toUpperCase() + user.gender!.substring(1)
                : null;
            _selectedBirthDate = user.birthDate != null
                ? DateTime.tryParse(user.birthDate!)
                : null;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          _showError('שגיאה בטעינת הפרופיל: $e');
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _selectBirthDate() async {
    if (!_isEditing) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Gender and birth date are now optional (can be set in settings)
    setState(() {
      _isSaving = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text.trim(),
        gender: _selectedGender?.toLowerCase(),
        birthDate: _selectedBirthDate != null ? _formatDate(_selectedBirthDate!) : null,
        height: double.parse(_heightController.text),
        initialWeight: double.parse(_weightController.text),
        coachName: _coachNameController.text.trim(),
        coachEmail: _coachEmailController.text.trim(),
        coachPhone: _coachPhoneController.text.trim().isEmpty
            ? null
            : _coachPhoneController.text.trim(),
      );

      await _firestoreService.setUser(authState.user.uid, updatedUser);

      if (mounted) {
        setState(() {
          _currentUser = updatedUser;
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הפרופיל עודכן בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('שגיאה בעדכון הפרופיל: $e');
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('פרופיל'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_currentUser == null) {
      return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('פרופיל'),
          ),
          body: const Center(child: Text('שגיאה בטעינת הפרופיל')),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ערוך פרופיל'),
          actions: [
            if (_isEditing)
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _isEditing = false;
                          _loadUserData();
                        });
                      },
                child: const Text('ביטול'),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: () {
                        if (_isEditing) {
                          _saveProfile();
                        } else {
                          setState(() {
                            _isEditing = true;
                          });
                        }
                      },
                      icon: Icon(_isEditing ? Icons.save : Icons.edit),
                    ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _currentUser!.photoUrl != null
                            ? NetworkImage(_currentUser!.photoUrl!)
                            : null,
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withAlpha(25),
                        child: _currentUser!.photoUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information Section
                Text(
                  'מידע אישי',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(
                    labelText: 'שם מלא',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'אנא הזן את שמך';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email (Read-only)
                TextFormField(
                  initialValue: _currentUser!.email,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'אימייל',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                // Gender (Optional)
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'מגדר (אופציונלי)',
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('זכר')),
                    DropdownMenuItem(value: 'Female', child: Text('נקבה')),
                  ],
                  onChanged: _isEditing
                      ? (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 16),

                // Birth Date (Optional)
                InkWell(
                  onTap: _isEditing ? _selectBirthDate : null,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'תאריך לידה (אופציונלי)',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedBirthDate == null
                          ? 'בחר תאריך'
                          : _formatDate(_selectedBirthDate!),
                      style: TextStyle(
                        color: _selectedBirthDate == null
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Height
                TextFormField(
                  controller: _heightController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(
                    labelText: 'גובה (ס"מ)',
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,1}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'אנא הזן את הגובה שלך';
                    }
                    final height = double.tryParse(value);
                    if (height == null || height < 100 || height > 250) {
                      return 'אנא הזן גובה תקף (100-250 ס"מ)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Weight
                TextFormField(
                  controller: _weightController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(
                    labelText: 'משקל (ק"ג)',
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,1}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'אנא הזן את המשקל שלך';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight < 30 || weight > 300) {
                      return 'אנא הזן משקל תקף (30-300 ק"ג)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Coach Details Section
                Text(
                  'פרטי המאמן',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Coach Name
                TextFormField(
                  controller: _coachNameController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(
                    labelText: 'שם המאמן',
                    prefixIcon: Icon(Icons.person_pin),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'אנא הזן שם מאמן';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Coach Email
                TextFormField(
                  controller: _coachEmailController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(
                    labelText: 'אימייל המאמן',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'אנא הזן אימייל מאמן';
                    }
                    if (!value.contains('@')) {
                      return 'אנא הזן אימייל תקף';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Coach Phone
                TextFormField(
                  controller: _coachPhoneController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(
                    labelText: 'טלפון המאמן',
                    prefixIcon: Icon(Icons.phone),
                    hintText: 'אופציונלי',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
