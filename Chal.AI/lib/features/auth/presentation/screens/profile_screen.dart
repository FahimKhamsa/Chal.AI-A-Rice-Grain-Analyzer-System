import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editMode = false;

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _designationCtrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _designationCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _designationCtrl.dispose();
    super.dispose();
  }

  void _enterEditMode(UserProfile profile) {
    _firstNameCtrl.text = profile.firstName;
    _lastNameCtrl.text = profile.lastName;
    _phoneCtrl.text = profile.phoneNumber;
    _locationCtrl.text = profile.location;
    _designationCtrl.text = profile.designation ?? '';
    setState(() {
      _editMode = true;
      _error = null;
    });
  }

  void _cancelEdit() => setState(() {
        _editMode = false;
        _error = null;
      });

  Future<void> _saveChanges(UserProfile current) async {
    final s = ref.read(appStringsProvider);
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final designation = _designationCtrl.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        location.isEmpty) {
      setState(() => _error = s.fillRequiredFields);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(profileNotifierProvider.notifier).saveUpdate(
            current.copyWith(
              firstName: firstName,
              lastName: lastName,
              phoneNumber: phone,
              location: location,
              designation: designation.isEmpty ? null : designation,
            ),
          );
      if (mounted) {
        setState(() => _editMode = false);
        final successS = ref.read(appStringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successS.profileUpdated,
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppTheme.healthyGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = ref.read(appStringsProvider).failedToSave);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final s = ref.watch(appStringsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: Text(s.failedToLoadProfile,
              style: GoogleFonts.inter(
                  color: cs.onSurface.withValues(alpha: 0.54))),
        ),
      ),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final initials =
            '${profile.firstName[0]}${profile.lastName[0]}'.toUpperCase();

        return Scaffold(
          drawer: const AppSidebar(),
          appBar: AppBar(
            elevation: 0,
            title: Text(
              s.profile,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            actions: [
              if (!_editMode)
                TextButton(
                  onPressed: () => _enterEditMode(profile),
                  child: Text(
                    s.edit,
                    style: GoogleFonts.inter(
                      color: AppTheme.healthyGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: _cancelEdit,
                  child: Text(
                    s.cancel,
                    style: GoogleFonts.inter(
                        color: cs.onSurface.withValues(alpha: 0.54),
                        fontSize: 15),
                  ),
                ),
                TextButton(
                  onPressed: _saving ? null : () => _saveChanges(profile),
                  child: _saving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.primary))
                      : Text(
                          s.save,
                          style: GoogleFonts.inter(
                            color: AppTheme.healthyGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.healthyGreen.withAlpha(40),
                      border: Border.all(
                        color: AppTheme.healthyGreen.withAlpha(80),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        color: AppTheme.healthyGreen,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.fullName,
                    style: GoogleFonts.inter(
                      color: cs.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: GoogleFonts.inter(
                        color: cs.onSurface.withValues(alpha: 0.54),
                        fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.brokenRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.brokenRed.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(
                            color: AppTheme.brokenRed, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131E17) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        if (_editMode) ...[
                          _EditRow(
                            label: s.firstName,
                            controller: _firstNameCtrl,
                            textInputAction: TextInputAction.next,
                          ),
                          Divider(color: cs.outlineVariant, height: 1),
                          _EditRow(
                            label: s.lastName,
                            controller: _lastNameCtrl,
                            textInputAction: TextInputAction.next,
                          ),
                          Divider(color: cs.outlineVariant, height: 1),
                          _EditRow(
                            label: s.phone,
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                          Divider(color: cs.outlineVariant, height: 1),
                          _EditRow(
                            label: s.location,
                            controller: _locationCtrl,
                            textInputAction: TextInputAction.next,
                          ),
                          Divider(color: cs.outlineVariant, height: 1),
                          _EditRow(
                            label: s.designation,
                            controller: _designationCtrl,
                            hint: s.optional,
                            textInputAction: TextInputAction.done,
                          ),
                        ] else ...[
                          _InfoRow(
                              label: s.firstName, value: profile.firstName),
                          Divider(color: cs.outlineVariant, height: 1),
                          _InfoRow(label: s.lastName, value: profile.lastName),
                          Divider(color: cs.outlineVariant, height: 1),
                          _InfoRow(label: s.email, value: profile.email),
                          Divider(color: cs.outlineVariant, height: 1),
                          _InfoRow(label: s.phone, value: profile.phoneNumber),
                          Divider(color: cs.outlineVariant, height: 1),
                          _InfoRow(label: s.location, value: profile.location),
                          if (profile.designation != null) ...[
                            Divider(color: cs.outlineVariant, height: 1),
                            _InfoRow(
                                label: s.designation,
                                value: profile.designation!),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: cs.onSurface.withValues(alpha: 0.38),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
                color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _EditRow({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: cs.onSurface.withValues(alpha: 0.38),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              style: GoogleFonts.inter(
                  color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                    color: cs.onSurface.withValues(alpha: 0.24), fontSize: 13),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: cs.onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppTheme.healthyGreen, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
