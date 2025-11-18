import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/services/storage_service.dart';
import 'package:muscleup/data/services/account_deletion_service.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _accountDeletionService = AccountDeletionService();
  final _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeletingAccount = false;
  bool _isUploadingImage = false;

  UserModel? _currentUser;
  File? _selectedImage;

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

  Future<void> _pickImage() async {
    // If not in editing mode, enable editing first
    if (!_isEditing) {
      setState(() {
        _isEditing = true;
      });
    }

    try {
      // Show options: Camera or Gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: const Text('בחר תמונה'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('מצלמה'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('גלריה'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null) return;

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Upload image immediately
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        _showError('שגיאה בבחירת תמונה: $e');
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final extension = _selectedImage!.path.split('.').last.toLowerCase();
      
      final imageUrl = await _storageService.uploadProfileImage(
        authState.user.uid,
        imageBytes,
        extension == 'jpg' || extension == 'jpeg' ? 'jpg' : 'png',
      );

      // Update user with new photo URL
      await _firestoreService.updateUser(authState.user.uid, {
        'photoUrl': imageUrl,
      });

      // Update local user model
      if (_currentUser != null) {
        setState(() {
          _currentUser = _currentUser!.copyWith(photoUrl: imageUrl);
          _isUploadingImage = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('התמונה הועלתה בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        _showError('שגיאה בהעלאת התמונה: $e');
      }
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

      // Upload image if selected
      if (_selectedImage != null && !_isUploadingImage) {
        await _uploadImage();
      }

      if (mounted) {
        setState(() {
          _currentUser = updatedUser;
          _isEditing = false;
          _isSaving = false;
          _selectedImage = null; // Clear selected image after save
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
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _isSaving || _isUploadingImage
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _isEditing
                      ? TextButton(
                          onPressed: _saveProfile,
                          child: const Text('שמור'),
                        )
                      : IconButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit),
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
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(60),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : _currentUser!.photoUrl != null
                                  ? NetworkImage(_currentUser!.photoUrl!)
                                  : null,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary.withAlpha(25),
                          child: _selectedImage == null && _currentUser!.photoUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : _isUploadingImage
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                    )
                              : null,
                        ),
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

                // Account Deletion Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.delete_forever,
                            color: Colors.red[600],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'מחיקת חשבון',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'מחיקת החשבון תמחק לצמיתות את כל המידע והנתונים שלך. פעולה זו אינה ניתנת לביטול.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isDeletingAccount ? null : _showAccountDeletionDialog,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('מחק חשבון'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountDeletionDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'מחיקת חשבון',
            style: TextStyle(color: Colors.red),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'האם אתה בטוח שברצונך למחוק את החשבון שלך?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'פעולה זו תמחק לצמיתות:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• כל המידע האישי שלך'),
              Text('• כל הנתונים וההיסטוריה'),
              Text('• כל הקבצים והחתימות'),
              SizedBox(height: 16),
              Text(
                'פעולה זו אינה ניתנת לביטול!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAccountDeletionConfirmationDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('המשך למחיקה'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountDeletionConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'אישור סופי למחיקה',
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            'זהו האישור האחרון. האם אתה בטוח לחלוטין שברצונך למחוק את החשבון שלך? פעולה זו אינה ניתנת לביטול.',
          ),
          actions: [
            TextButton(
              onPressed: _isDeletingAccount
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: _isDeletingAccount ? null : _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: _isDeletingAccount
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('מחק חשבון לצמיתות'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('לא נמצא משתמש מחובר'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await _accountDeletionService.deleteAccount(user.uid);

      if (mounted) {
        // Close any open dialogs
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Sign out and navigate to login
        context.read<AuthBloc>().add(const AuthSignOutRequested());
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('החשבון נמחק בהצלחה'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
        Navigator.of(context).pop(); // Close confirmation dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה במחיקת החשבון: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
