import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../providers/profile_provider.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../services/profile_service.dart';
import '../../utils/location_result.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_gradient_button.dart';
import '../post-auth/main_shell_screen.dart';
import '../shared/location_picker_screen.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  /// When true (onboarding flow), navigates to MainShellScreen on success.
  /// When false (from profile banner), pops and refreshes profile.
  final bool onboarding;

  /// Existing profile data — used only for incompleteFields filtering.
  final UserProfile? profile;

  /// When true, only show fields listed in [profile.incompleteFields].
  final bool filterToIncomplete;

  const CompleteProfileScreen({
    super.key,
    this.onboarding = false,
    this.profile,
    this.filterToIncomplete = false,
  });

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  // Local image picked by user
  File? _profileImage;
  // Existing avatar URL from API (shown when no local image selected)
  String? _existingAvatarUrl;

  String? _username;
  final _fullNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  DateTime? _dob;
  bool? _isVeg;
  final Set<int> _selectedCuisines = {};
  LocationResult? _selectedLocation;

  bool _submitted = false;
  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final details = await ProfileService().getUserDetails();
      if (!mounted) return;
      setState(() {
        _username = details.username;
        _fullNameCtrl.text = details.name;
        _bioCtrl.text = details.bio;
        _existingAvatarUrl = details.avatar;

        if (details.dob != null) {
          _dob = DateTime.tryParse(details.dob!);
        }

        if (details.diet != null) {
          _isVeg = details.diet == 'veg';
        }

        if (details.foodPreference != null && details.foodPreference!.isNotEmpty) {
          final names = details.foodPreference!
              .split(', ')
              .map((s) => s.trim())
              .toSet();
          for (var i = 0; i < AppData.cuisines.length; i++) {
            if (names.contains(AppData.cuisines[i]['name'])) {
              _selectedCuisines.add(i);
            }
          }
        }

        if (details.latitude != null && details.longitude != null) {
          _selectedLocation = LocationResult(
            latitude: details.latitude!,
            longitude: details.longitude!,
            address: 'Saved location',
          );
        }

        _loadingDetails = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDetails = false);
    }
  }

  // Returns true if this field should be shown to the user.
  bool _shouldShow(String field) {
    if (!widget.filterToIncomplete || widget.profile == null) return true;
    return widget.profile!.incompleteFields.contains(field);
  }

  // In edit mode (not onboarding, not filterToIncomplete), only name is
  // required. All other fields are optional — the PATCH sends only what's set.
  bool get _strictValidation => widget.onboarding || widget.filterToIncomplete;

  // ── Validators ──────────────────────────────────────────────────────────────

  String? get _fullNameError {
    if (!_submitted) return null;
    if (_fullNameCtrl.text.trim().isEmpty) return AppData.profileErrorFullName;
    return null;
  }

  String? get _dobError {
    if (!_submitted || !_strictValidation) return null;
    if (_dob == null) return AppData.profileErrorDob;
    final cutoff = DateTime.now().subtract(const Duration(days: 365 * 13 + 3));
    if (_dob!.isAfter(cutoff)) return AppData.profileErrorDobAge;
    return null;
  }

  String? get _foodTypeError {
    if (!_submitted || !_strictValidation) return null;
    if (_isVeg == null) return AppData.profileErrorFoodType;
    return null;
  }

  String? get _cuisineError {
    if (!_submitted || !_strictValidation) return null;
    if (_selectedCuisines.isEmpty) return AppData.profileErrorCuisines;
    return null;
  }

  String? get _locationError {
    if (!_submitted || !_strictValidation) return null;
    if (_selectedLocation == null) return AppData.profileErrorLocation;
    return null;
  }

  bool get _isValid {
    if (_shouldShow('name') && _fullNameError != null) return false;
    if (_shouldShow('dob') && _dobError != null) return false;
    if (_shouldShow('diet') && _foodTypeError != null) return false;
    if (_shouldShow('food_preference') && _cuisineError != null) return false;
    if (_shouldShow('location') && _locationError != null) return false;
    return true;
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

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

  Future<void> _openLocationPicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          onConfirm: (result) {
            if (mounted) setState(() => _selectedLocation = result);
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_isValid) return;

    final cuisineNames = _selectedCuisines
        .map((i) => AppData.cuisines[i]['name']!)
        .join(', ');

    await ref.read(completeProfileNotifierProvider.notifier).submit(
          avatarFile: _shouldShow('avatar') ? _profileImage : null,
          name: _shouldShow('name') ? _fullNameCtrl.text.trim() : null,
          bio: _shouldShow('bio')
              ? (_bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim())
              : null,
          dob: _shouldShow('dob')
              ? (_dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null)
              : null,
          diet: _shouldShow('diet') && _isVeg != null
              ? (_isVeg! ? 'veg' : 'non_veg')
              : null,
          foodPreference: _shouldShow('food_preference') && _selectedCuisines.isNotEmpty
              ? cuisineNames
              : null,
          lat: _shouldShow('location') ? _selectedLocation?.latitude : null,
          lon: _shouldShow('location') ? _selectedLocation?.longitude : null,
        );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(completeProfileNotifierProvider);

    ref.listen(completeProfileNotifierProvider, (_, next) {
      if (next.stage == ProfileUpdateStage.done) {
        if (widget.onboarding) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainShellScreen()),
            (_) => false,
          );
        } else {
          ref.invalidate(profileProvider);
          Navigator.pop(context);
        }
      } else if (next.stage == ProfileUpdateStage.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade400,
          ),
        );
        ref.read(completeProfileNotifierProvider.notifier).clearError();
      }
    });

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary),
              onPressed: notifier.isLoading ? null : () => Navigator.pop(context),
            ),
          ),
          body: _loadingDetails
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : Column(
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

                            if (_shouldShow('avatar')) ...[
                              _buildProfilePhoto(),
                              SizedBox(height: context.hp(3.5)),
                            ],

                            // Username (always shown, read-only)
                            if (_username != null) ...[
                              _sectionTitle('Account'),
                              _buildReadOnlyField(
                                label: 'Username',
                                value: '@$_username',
                              ),
                              SizedBox(height: context.hp(3.5)),
                            ],

                            if (_shouldShow('name') || _shouldShow('dob')) ...[
                              _sectionTitle('Basic Info'),
                              if (_shouldShow('name')) ...[
                                _buildTextField(
                                  controller: _fullNameCtrl,
                                  hint: AppData.profileFullNameHint,
                                  label: AppData.profileFullName,
                                  errorText: _fullNameError,
                                  onChanged: (_) => setState(() {}),
                                ),
                                if (_shouldShow('dob'))
                                  SizedBox(height: context.hp(1.8)),
                              ],
                              if (_shouldShow('dob')) _buildDobField(),
                              SizedBox(height: context.hp(3.5)),
                            ],

                            if (_shouldShow('bio')) ...[
                              _sectionTitle('About You'),
                              _buildTextField(
                                controller: _bioCtrl,
                                hint: AppData.profileBioHint,
                                label: AppData.profileBio,
                                multiline: true,
                                maxLength: 120,
                              ),
                              SizedBox(height: context.hp(3.5)),
                            ],

                            if (_shouldShow('diet')) ...[
                              _sectionTitle(AppData.profileFoodType),
                              _buildFoodTypeToggle(),
                              if (_foodTypeError != null) ...[
                                SizedBox(height: context.hp(0.6)),
                                _errorText(_foodTypeError!),
                              ],
                              SizedBox(height: context.hp(3.5)),
                            ],

                            if (_shouldShow('food_preference')) ...[
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
                            ],

                            if (_shouldShow('location')) ...[
                              _sectionTitle(AppData.profileLocation),
                              _buildLocationField(),
                              if (_locationError != null) ...[
                                SizedBox(height: context.hp(0.6)),
                                _errorText(_locationError!),
                              ],
                              SizedBox(height: context.hp(2)),
                            ],
                          ],
                        ),
                      ),
                    ),

                    Container(
                      color: AppColors.background,
                      padding: EdgeInsets.fromLTRB(
                        context.wp(6),
                        context.hp(1.5),
                        context.wp(6),
                        context.hp(3) + MediaQuery.of(context).padding.bottom,
                      ),
                      child: _buildSubmitButton(notifier),
                    ),
                  ],
                ),
        ),

        if (notifier.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.35),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: context.hp(2)),
                  Text(
                    _stageLabel(notifier.stage),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _stageLabel(ProfileUpdateStage stage) {
    switch (stage) {
      case ProfileUpdateStage.gettingUrl:
        return 'Preparing upload…';
      case ProfileUpdateStage.uploadingAvatar:
        return 'Uploading photo…';
      case ProfileUpdateStage.updating:
        return 'Saving profile…';
      default:
        return '';
    }
  }

  Widget _buildSubmitButton(ProfileUpdateState notifier) {
    if (notifier.isLoading) {
      return AppGradientButton(label: AppData.profileComplete, onTap: null);
    }
    return AppGradientButton(label: AppData.profileComplete, onTap: _submit);
  }

  // ── Section helpers ──────────────────────────────────────────────────────────

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

  // ── Read-only field ──────────────────────────────────────────────────────────

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(1.8),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.greyDark,
              fontSize: context.sp(12),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(15),
              color: AppColors.greyDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile photo ────────────────────────────────────────────────────────────

  Widget _buildProfilePhoto() {
    final hasLocal = _profileImage != null;
    final hasRemote = _existingAvatarUrl != null;
    final hasImage = hasLocal || hasRemote;

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
                  color: hasImage ? AppColors.primary : const Color(0xFFE0E0E0),
                  width: hasImage ? 3 : 2,
                ),
                color: const Color(0xFFF5F0FF),
              ),
              child: ClipOval(
                child: hasLocal
                    ? Image.file(_profileImage!, fit: BoxFit.cover)
                    : hasRemote
                        ? Image.network(
                            _existingAvatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: AppColors.grey,
                                size: context.wp(10),
                              ),
                            ),
                          )
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

  // ── Text field ───────────────────────────────────────────────────────────────

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

  // ── DOB field ────────────────────────────────────────────────────────────────

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
                      const SizedBox(height: 2),
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

  // ── Location field ───────────────────────────────────────────────────────────

  Widget _buildLocationField() {
    final hasError = _locationError != null;
    return GestureDetector(
      onTap: _openLocationPicker,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(4),
          vertical: context.hp(1.9),
        ),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppData.profileLocation,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.greyDark,
                      fontSize: context.sp(12),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedLocation?.address ?? AppData.profileLocationHint,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(15),
                      color: _selectedLocation != null
                          ? Colors.black87
                          : AppColors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.place_rounded, color: AppColors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Food type toggle ─────────────────────────────────────────────────────────

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

  // ── Cuisine grid ─────────────────────────────────────────────────────────────

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
            padding: EdgeInsets.symmetric(vertical: context.hp(1.5)),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
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
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    color:
                        selected ? AppColors.primary : AppColors.greyDark,
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
