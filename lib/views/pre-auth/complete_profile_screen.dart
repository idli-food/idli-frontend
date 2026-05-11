import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_gradient_button.dart';
import '../post-auth/main_shell_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  File? _profileImage;
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  DateTime? _dob;
  bool? _isVeg;
  final Set<int> _selectedCuisines = {};
  bool _submitted = false;

  // ── Validators ─────────────────────────────────────────────────────────────

  String? get _usernameError {
    if (!_submitted) return null;
    final v = _usernameCtrl.text.trim();
    if (v.isEmpty) return AppData.profileErrorUsername;
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{2,19}$').hasMatch(v)) {
      return AppData.profileErrorUsernameFormat;
    }
    return null;
  }

  String? get _fullNameError {
    if (!_submitted) return null;
    if (_fullNameCtrl.text.trim().isEmpty) return AppData.profileErrorFullName;
    return null;
  }

  String? get _dobError {
    if (!_submitted) return null;
    if (_dob == null) return AppData.profileErrorDob;
    final cutoff = DateTime.now().subtract(const Duration(days: 365 * 13 + 3));
    if (_dob!.isAfter(cutoff)) return AppData.profileErrorDobAge;
    return null;
  }

  String? get _foodTypeError {
    if (!_submitted) return null;
    if (_isVeg == null) return AppData.profileErrorFoodType;
    return null;
  }

  String? get _cuisineError {
    if (!_submitted) return null;
    if (_selectedCuisines.isEmpty) return AppData.profileErrorCuisines;
    return null;
  }

  String? get _locationError {
    if (!_submitted) return null;
    if (_locationCtrl.text.trim().isEmpty) return AppData.profileErrorLocation;
    return null;
  }

  bool get _isValid =>
      _usernameError == null &&
      _fullNameError == null &&
      _dobError == null &&
      _foodTypeError == null &&
      _cuisineError == null &&
      _locationError == null;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() => _profileImage = File(file.path));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 13, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: maxDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_isValid) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.wp(6),
                0,
                context.wp(6),
                context.hp(2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppData.profileTitle,
                    style: AppTextStyles.primary.copyWith(
                      fontSize: context.sp(30),
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: context.hp(0.6)),
                  Text(
                    AppData.profileSubtitle,
                    style: AppTextStyles.secondary.copyWith(
                      fontSize: context.sp(14),
                    ),
                  ),
                  SizedBox(height: context.hp(3)),

                  // Profile photo
                  _buildProfilePhoto(),
                  SizedBox(height: context.hp(3.5)),

                  // Basic info
                  _sectionTitle('Basic Info'),
                  _buildTextField(
                    controller: _usernameCtrl,
                    hint: AppData.profileUsernameHint,
                    label: AppData.profileUsername,
                    errorText: _usernameError,
                    formatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9_]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: context.hp(1.8)),
                  _buildTextField(
                    controller: _fullNameCtrl,
                    hint: AppData.profileFullNameHint,
                    label: AppData.profileFullName,
                    errorText: _fullNameError,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: context.hp(1.8)),
                  _buildDobField(),
                  SizedBox(height: context.hp(3.5)),

                  // Bio
                  _sectionTitle('About You'),
                  _buildTextField(
                    controller: _bioCtrl,
                    hint: AppData.profileBioHint,
                    label: AppData.profileBio,
                    multiline: true,
                    maxLength: 120,
                  ),
                  SizedBox(height: context.hp(3.5)),

                  // Food preference
                  _sectionTitle(AppData.profileFoodType),
                  _buildFoodTypeToggle(),
                  if (_foodTypeError != null) ...[
                    SizedBox(height: context.hp(0.6)),
                    _errorText(_foodTypeError!),
                  ],
                  SizedBox(height: context.hp(3.5)),

                  // Cuisines
                  _sectionTitle(AppData.profileCuisines),
                  Text(
                    AppData.profileCuisinesHint,
                    style: AppTextStyles.secondary.copyWith(
                        fontSize: context.sp(12)),
                  ),
                  SizedBox(height: context.hp(1.2)),
                  _buildCuisineGrid(),
                  if (_cuisineError != null) ...[
                    SizedBox(height: context.hp(0.8)),
                    _errorText(_cuisineError!),
                  ],
                  SizedBox(height: context.hp(3.5)),

                  // Location
                  _sectionTitle(AppData.profileLocation),
                  _buildTextField(
                    controller: _locationCtrl,
                    hint: AppData.profileLocationHint,
                    label: AppData.profileLocation,
                    errorText: _locationError,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_locationError != null) ...[
                    SizedBox(height: context.hp(0.6)),
                    _errorText(_locationError!),
                  ],
                  SizedBox(height: context.hp(2)),
                ],
              ),
            ),
          ),

          // Sticky submit button
          Container(
            color: AppColors.background,
            padding: EdgeInsets.fromLTRB(
              context.wp(6),
              context.hp(1.5),
              context.wp(6),
              context.hp(3) + MediaQuery.of(context).padding.bottom,
            ),
            child: AppGradientButton(
              label: AppData.profileComplete,
              onTap: _submit,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section helpers ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.hp(1.2)),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: context.sp(11),
          fontWeight: FontWeight.w700,
          color: AppColors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _errorText(String text) {
    return Padding(
      padding: EdgeInsets.only(left: context.wp(2)),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          color: Colors.red.shade400,
          fontSize: context.sp(12),
        ),
      ),
    );
  }

  // ── Profile photo ───────────────────────────────────────────────────────────

  Widget _buildProfilePhoto() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: context.wp(25),
              height: context.wp(25),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _profileImage != null
                      ? AppColors.primary
                      : const Color(0xFFE0E0E0),
                  width: _profileImage != null ? 3 : 2,
                ),
                color: const Color(0xFFF5F0FF),
              ),
              child: ClipOval(
                child: _profileImage != null
                    ? Image.file(_profileImage!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.grey,
                          size: context.wp(10),
                        ),
                      ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: context.wp(8),
                height: context.wp(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: context.sp(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Text field ──────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    String? errorText,
    bool multiline = false,
    int? maxLength,
    List<TextInputFormatter>? formatters,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? Colors.red.shade400 : const Color(0xFFE0E0E0),
              width: hasError ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: multiline ? 4 : 1,
            maxLength: maxLength,
            inputFormatters: formatters,
            textAlignVertical:
                multiline ? TextAlignVertical.top : TextAlignVertical.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(15),
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: label,
              alignLabelWithHint: multiline,
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.greyDark,
                fontSize: context.sp(13),
              ),
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.grey,
                fontSize: context.sp(14),
              ),
              border: InputBorder.none,
              contentPadding: multiline
                  ? EdgeInsets.fromLTRB(
                      context.wp(4),
                      context.hp(1.5),
                      context.wp(4),
                      context.hp(1.5),
                    )
                  : EdgeInsets.symmetric(
                      horizontal: context.wp(4),
                      vertical: context.hp(1.8),
                    ),
              counterStyle: TextStyle(
                  color: AppColors.grey, fontSize: context.sp(11)),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: context.hp(0.5)),
          _errorText(errorText),
        ],
      ],
    );
  }

  // ── DOB field ───────────────────────────────────────────────────────────────

  Widget _buildDobField() {
    final formatted = _dob != null
        ? DateFormat('dd MMM yyyy').format(_dob!)
        : null;
    final hasError = _dobError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.wp(4),
              vertical: context.hp(1.9),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasError
                    ? Colors.red.shade400
                    : const Color(0xFFE0E0E0),
                width: hasError ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppData.profileDob,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.greyDark,
                          fontSize: context.sp(12),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        formatted ?? AppData.profileDobHint,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: context.sp(15),
                          color: formatted != null
                              ? Colors.black87
                              : AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.calendar_today_rounded,
                    color: AppColors.grey, size: 18),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: context.hp(0.5)),
          _errorText(_dobError!),
        ],
      ],
    );
  }

  // ── Food type toggle ────────────────────────────────────────────────────────

  Widget _buildFoodTypeToggle() {
    return Row(
      children: [
        Expanded(child: _foodPill(label: AppData.profileVeg, isVeg: true)),
        SizedBox(width: context.wp(3)),
        Expanded(child: _foodPill(label: AppData.profileNonVeg, isVeg: false)),
      ],
    );
  }

  Widget _foodPill({required String label, required bool isVeg}) {
    final selected = _isVeg == isVeg;
    return GestureDetector(
      onTap: () => setState(() => _isVeg = isVeg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: context.hp(6.5),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: selected ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVeg ? '🥦' : '🍗',
                style: TextStyle(fontSize: context.sp(16)),
              ),
              SizedBox(width: context.wp(2)),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(15),
                  color: selected ? AppColors.accent : AppColors.greyDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cuisine grid ────────────────────────────────────────────────────────────

  Widget _buildCuisineGrid() {
    final tileWidth =
        (context.wp(100) - context.wp(12) - context.wp(3)) / 2;
    return Wrap(
      spacing: context.wp(3),
      runSpacing: context.hp(1.2),
      children: List.generate(AppData.cuisines.length, (i) {
        final cuisine = AppData.cuisines[i];
        final selected = _selectedCuisines.contains(i);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedCuisines.remove(i);
            } else {
              _selectedCuisines.add(i);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: tileWidth,
            padding: EdgeInsets.symmetric(
              vertical: context.hp(1.5),
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    selected ? AppColors.primary : const Color(0xFFE0E0E0),
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  cuisine['emoji']!,
                  style: TextStyle(fontSize: context.sp(26)),
                ),
                SizedBox(height: context.hp(0.6)),
                Text(
                  cuisine['name']!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: context.sp(13),
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selected ? AppColors.primary : AppColors.greyDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

}
