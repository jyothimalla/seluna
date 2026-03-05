import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/providers.dart';

// ── Avatar definitions ────────────────────────────────────────────────────────
const _kAvatars = [
  ('🌸', [Color(0xFFFFB7C5), Color(0xFFFF85A1)]),
  ('🦋', [Color(0xFFCE93D8), Color(0xFFBA68C8)]),
  ('🌺', [Color(0xFFFFAB91), Color(0xFFFF7043)]),
  ('🌻', [Color(0xFFFFE082), Color(0xFFFFB300)]),
  ('🌹', [Color(0xFFEF9A9A), Color(0xFFE57373)]),
  ('🌙', [Color(0xFF90CAF9), Color(0xFF64B5F6)]),
  ('⭐', [Color(0xFFFFF176), Color(0xFFFFD600)]),
  ('🌈', [Color(0xFF80DEEA), Color(0xFF4DD0E1)]),
  ('🦄', [Color(0xFFB39DDB), Color(0xFF9575CD)]),
  ('🐱', [Color(0xFFA5D6A7), Color(0xFF81C784)]),
  ('🌷', [Color(0xFFF48FB1), Color(0xFFEC407A)]),
  ('💖', [Color(0xFFFF80AB), Color(0xFFFF4081)]),
];

Widget _buildEmojiAvatar(int index, {double radius = 40}) {
  final (emoji, colors) = _kAvatars[index.clamp(0, _kAvatars.length - 1)];
  return Container(
    width: radius * 2,
    height: radius * 2,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.last.withAlpha(80),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Center(
      child: Text(emoji, style: TextStyle(fontSize: radius * 0.85)),
    ),
  );
}

/// Shows either the custom photo (if set) or the emoji avatar.
Widget buildProfileAvatar({
  required String? photoPath,
  required int avatarIndex,
  double radius = 40,
}) {
  if (!kIsWeb && photoPath != null && photoPath.isNotEmpty) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E8C).withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.file(
          File(photoPath),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) =>
              _buildEmojiAvatar(avatarIndex, radius: radius),
        ),
      ),
    );
  }
  return _buildEmojiAvatar(avatarIndex, radius: radius);
}

// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // ── Accent colours for each section ───────────────────────────────────────
  static const _pink = Color(0xFFE91E8C);
  static const _purple = Color(0xFF9C27B0);
  static const _orange = Color(0xFFFF7043);
  static const _indigo = Color(0xFF5C6BC0);
  static const _red = Color(0xFFE53935);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(periodServiceProvider);
    final profile = service.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A0A1F) : const Color(0xFFF8F0FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header banner ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: _purple,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Profile & Settings',
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildHeaderBanner(context, ref, profile),
            ),
          ),

          // ── Settings sections ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _buildSections(context, ref, profile, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header banner ──────────────────────────────────────────────────────────
  Widget _buildHeaderBanner(
      BuildContext context, WidgetRef ref, dynamic profile) {
    final name = (profile.name != null && profile.name!.isNotEmpty)
        ? profile.name!
        : 'Your Profile';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFFAD1457), Color(0xFFFF4081)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Avatar with camera badge
            GestureDetector(
              onTap: () => _showPhotoOptions(
                  context, ref, profile.avatarIndex, profile.photoPath),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: buildProfileAvatar(
                      photoPath: profile.photoPath,
                      avatarIndex: profile.avatarIndex,
                      radius: 54,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4081),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showPhotoOptions(
                  context, ref, profile.avatarIndex, profile.photoPath),
              child: const Text(
                '✏️  Change Photo',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Settings sections ──────────────────────────────────────────────────────
  List<Widget> _buildSections(
      BuildContext context, WidgetRef ref, dynamic profile, bool isDark) {
    return [
      // Personal
      _section(
        context,
        title: 'Personal',
        icon: Icons.person_outline,
        color: _pink,
        isDark: isDark,
        tiles: [
          _tile(
            context,
            icon: Icons.badge_outlined,
            iconColor: _pink,
            title: 'Name',
            subtitle: (profile.name != null && profile.name!.isNotEmpty)
                ? profile.name!
                : 'Tap to set your name',
            onTap: () => _editName(context, ref, profile.name),
          ),
          _tile(
            context,
            icon: Icons.cake_outlined,
            iconColor: const Color(0xFFEC407A),
            title: 'Age',
            subtitle: profile.age != null
                ? '${profile.age} years old'
                : 'Tap to set your age',
            isLast: true,
            onTap: () => _editAge(context, ref, profile.age),
          ),
        ],
      ),

      // Health Metrics
      _section(
        context,
        title: 'Health Metrics',
        icon: Icons.favorite_outline,
        color: _purple,
        isDark: isDark,
        tiles: [
          _tile(
            context,
            icon: Icons.monitor_weight_outlined,
            iconColor: _purple,
            title: 'Weight',
            subtitle: profile.weightKg != null
                ? '${profile.weightKg!.toStringAsFixed(1)} kg'
                : 'Tap to set weight',
            onTap: () => _editDecimal(
              context,
              ref,
              title: 'Update Weight',
              label: 'Weight (kg)',
              current: profile.weightKg,
              onSave: (v) =>
                  ref.read(periodServiceProvider).updateWeight(v),
              successMsg: (v) =>
                  'Weight updated to ${v.toStringAsFixed(1)} kg.',
            ),
          ),
          _tile(
            context,
            icon: Icons.height_outlined,
            iconColor: const Color(0xFF7B1FA2),
            title: 'Height',
            subtitle: profile.heightCm != null
                ? '${profile.heightCm!.toStringAsFixed(0)} cm'
                : 'Tap to set height',
            isLast: profile.bmi == null,
            onTap: () => _editDecimal(
              context,
              ref,
              title: 'Update Height',
              label: 'Height (cm)',
              current: profile.heightCm,
              onSave: (v) =>
                  ref.read(periodServiceProvider).updateHeight(v),
              successMsg: (v) =>
                  'Height updated to ${v.toStringAsFixed(0)} cm.',
            ),
          ),
          if (profile.bmi != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _bmiCard(context, profile.bmi!),
            ),
        ],
      ),

      // Reminders
      _section(
        context,
        title: 'Reminders',
        icon: Icons.notifications_outlined,
        color: _orange,
        isDark: isDark,
        tiles: [
          _tile(
            context,
            icon: profile.notificationsEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            iconColor: _orange,
            title: 'Period Reminders',
            subtitle: profile.notificationsEnabled
                ? 'Notified 2 days before every period'
                : 'Reminders are turned off',
            isLast: true,
            showChevron: false,
            trailing: Switch.adaptive(
              value: profile.notificationsEnabled,
              activeTrackColor: _orange,
              onChanged: (val) => ref
                  .read(periodServiceProvider)
                  .setNotificationsEnabled(val),
            ),
          ),
        ],
      ),

      // Appearance
      _section(
        context,
        title: 'Appearance',
        icon: Icons.palette_outlined,
        color: _indigo,
        isDark: isDark,
        tiles: [
          _tile(
            context,
            icon: profile.isDarkMode
                ? Icons.dark_mode
                : Icons.light_mode_outlined,
            iconColor: _indigo,
            title: 'Dark Mode',
            subtitle: profile.isDarkMode ? 'On' : 'Off',
            isLast: true,
            showChevron: false,
            trailing: Switch.adaptive(
              value: profile.isDarkMode,
              activeTrackColor: _indigo,
              onChanged: (val) =>
                  ref.read(periodServiceProvider).setDarkMode(val),
            ),
          ),
        ],
      ),

      // Data
      _section(
        context,
        title: 'Data',
        icon: Icons.storage_outlined,
        color: _red,
        isDark: isDark,
        tiles: [
          _tile(
            context,
            icon: Icons.delete_forever_outlined,
            iconColor: _red,
            title: 'Delete All Data',
            subtitle: 'Remove all period logs and reset the app',
            isLast: true,
            onTap: () => _confirmDeleteAll(context, ref),
          ),
        ],
      ),
    ];
  }

  // ── Section container ──────────────────────────────────────────────────────
  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required List<Widget> tiles,
  }) {
    final cardColor = isDark ? const Color(0xFF2A1535) : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 0, 10),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(20),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(children: tiles),
          ),
        ),
      ],
    );
  }

  // ── Individual tile ────────────────────────────────────────────────────────
  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool isLast = false,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade500,
                  ),
                )
              : null,
          trailing: trailing ??
              (onTap != null && showChevron
                  ? Icon(Icons.chevron_right,
                      color: Colors.grey.shade400, size: 20)
                  : null),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: Colors.grey.withAlpha(30),
          ),
      ],
    );
  }

  // ── BMI card (inline within Health Metrics card) ───────────────────────────
  Widget _bmiCard(BuildContext context, double bmi) {
    final String category;
    final String suggestion;
    final Color accent;
    final IconData moodIcon;

    if (bmi < 18.5) {
      category = 'Underweight';
      suggestion =
          'Low body weight can affect cycle regularity. Consider speaking with a nutritionist.';
      accent = Colors.blue.shade600;
      moodIcon = Icons.trending_down;
    } else if (bmi < 25) {
      category = 'Healthy Weight ✓';
      suggestion =
          'Great! A healthy weight supports regular menstrual cycles.';
      accent = const Color(0xFF43A047);
      moodIcon = Icons.check_circle_outline;
    } else if (bmi < 30) {
      category = 'Overweight';
      suggestion =
          'A healthy weight can help regulate cycles and reduce cramp severity.';
      accent = Colors.orange.shade700;
      moodIcon = Icons.warning_amber_outlined;
    } else {
      category = 'Obese';
      suggestion =
          'Weight management may positively impact your menstrual health. Consult a healthcare provider.';
      accent = Colors.red.shade600;
      moodIcon = Icons.warning_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withAlpha(18), accent.withAlpha(8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Row(
        children: [
          // BMI circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: accent.withAlpha(28),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'BMI',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(moodIcon, color: accent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      category,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '* Not a substitute for medical advice.',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo / Avatar options bottom sheet ───────────────────────────────────
  Future<void> _showPhotoOptions(BuildContext context, WidgetRef ref,
      int currentAvatar, String? currentPhoto) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Change Photo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _sheetOption(ctx, Icons.camera_alt_outlined,
                  'Take a Photo', 'camera'),
              _sheetOption(ctx, Icons.photo_library_outlined,
                  'Choose from Gallery', 'gallery'),
              _sheetOption(ctx, Icons.emoji_emotions_outlined,
                  'Choose an Avatar', 'avatar'),
              if (currentPhoto != null)
                _sheetOption(ctx, Icons.person_outline,
                    'Remove Custom Photo', 'remove'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted) return;

    switch (action) {
      case 'camera':
        await _pickPhoto(context, ref, ImageSource.camera);
        break;
      case 'gallery':
        await _pickPhoto(context, ref, ImageSource.gallery);
        break;
      case 'avatar':
        await _showAvatarPicker(context, ref, currentAvatar);
        break;
      case 'remove':
        await ref.read(periodServiceProvider).updatePhotoPath(null);
        break;
    }
  }

  Widget _sheetOption(
      BuildContext ctx, IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE91E8C).withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFE91E8C), size: 20),
      ),
      title: Text(label),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  // ── Pick photo from camera or gallery ────────────────────────────────────
  Future<void> _pickPhoto(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Photo picker is only available on mobile.')),
      );
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      if (!context.mounted) return;

      final dir = await getApplicationDocumentsDirectory();
      final dest =
          '${dir.path}/profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(picked.path).copy(dest);

      await ref.read(periodServiceProvider).updatePhotoPath(dest);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick photo: $e')),
        );
      }
    }
  }

  // ── Emoji avatar picker dialog ────────────────────────────────────────────
  Future<void> _showAvatarPicker(
      BuildContext context, WidgetRef ref, int current) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Your Avatar',
            style: TextStyle(fontWeight: FontWeight.bold)),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: SizedBox(
          width: 280,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            itemCount: _kAvatars.length,
            itemBuilder: (ctx, i) {
              final isSelected = i == current;
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, i),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildEmojiAvatar(i, radius: 28),
                    if (isSelected)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE91E8C),
                            width: 3,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (picked != null && context.mounted) {
      await ref.read(periodServiceProvider).updateAvatar(picked);
    }
  }

  // ── Generic decimal editor ────────────────────────────────────────────────
  Future<void> _editDecimal(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String label,
    required double? current,
    required Future<void> Function(double?) onSave,
    required String Function(double) successMsg,
  }) async {
    final controller = TextEditingController(
        text: current != null ? current.toStringAsFixed(1) : '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: KiwiNovasTextField(
          controller: controller,
          labelText: label,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );

    controller.dispose();
    if (!context.mounted) return;

    if (result != null) {
      final parsed = double.tryParse(result);
      await onSave(parsed);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(parsed != null
              ? successMsg(parsed)
              : '$label cleared.'),
        ));
      }
    }
  }

  // ── Edit name ─────────────────────────────────────────────────────────────
  Future<void> _editName(
      BuildContext context, WidgetRef ref, String? currentName) async {
    final controller = TextEditingController(text: currentName ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Name'),
        content: KiwiNovasTextField(
          controller: controller,
          labelText: 'Your name',
          keyboardType: TextInputType.name,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (!context.mounted) return;

    if (result != null) {
      await ref
          .read(periodServiceProvider)
          .updateName(result.isEmpty ? null : result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.isEmpty
                  ? 'Name cleared.'
                  : 'Name updated to $result.')),
        );
      }
    }
  }

  // ── Edit age ──────────────────────────────────────────────────────────────
  Future<void> _editAge(
      BuildContext context, WidgetRef ref, int? currentAge) async {
    final controller = TextEditingController(
      text: currentAge?.toString() ?? '',
    );

    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Age'),
        content: KiwiNovasTextField(
          controller: controller,
          labelText: 'Age',
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (!context.mounted) return;

    if (result != null) {
      await ref.read(periodServiceProvider).updateAge(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Age updated to $result.')),
        );
      }
    }
  }

  // ── Confirm delete all ────────────────────────────────────────────────────
  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This will permanently remove all period logs and reset your '
          'profile. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(periodServiceProvider).deleteAllData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data deleted.')),
      );
    }
  }
}
