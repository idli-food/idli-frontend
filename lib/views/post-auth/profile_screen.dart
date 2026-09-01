import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/profile_provider.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../utils/token_storage.dart';
import '../../widgets/shared/app_shimmer.dart';
import '../pre-auth/complete_profile_screen.dart';
import '../pre-auth/welcome_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await TokenStorage.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => _buildShimmer(context),
        error: (e, _) => _buildError(context, ref, e),
        data: (profile) => _buildContent(context, ref, profile),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, UserProfile profile) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(profileProvider),
      color: AppColors.primary,
      child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopSection(profile: profile, onLogout: () => _logout(context)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.hp(2.5)),
                _StatsCard(profile: profile),
                SizedBox(height: context.hp(2)),
                _ActionButtons(ref: ref, profile: profile),
                if (!profile.isProfileComplete) ...[
                  SizedBox(height: context.hp(1.5)),
                  _CompletionBanner(profile: profile),
                ],
                SizedBox(height: context.hp(2.5)),
                const _HighlightsSection(),
              ],
            ),
          ),
          SizedBox(height: context.hp(1.5)),
          _PostsGrid(posts: profile.posts),
          SizedBox(height: context.hp(2)),
          _LogoutButton(onLogout: () => _logout(context)),
          SizedBox(height: context.hp(4)),
        ],
      ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.hp(20)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
            child: Column(
              children: [
                AppShimmer(
                  height: context.hp(12),
                  borderRadius: BorderRadius.circular(18),
                ),
                SizedBox(height: context.hp(2)),
                AppShimmer(
                  height: context.hp(6),
                  borderRadius: BorderRadius.circular(14),
                ),
                SizedBox(height: context.hp(2.5)),
                AppShimmer(
                  height: context.hp(8),
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),
          SizedBox(height: context.hp(1.5)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 0.5,
              mainAxisSpacing: 0.5,
            ),
            itemCount: 9,
            itemBuilder: (_, __) => AppShimmer(borderRadius: BorderRadius.zero),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object e) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.wp(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: context.sp(48), color: AppColors.greyDark),
            SizedBox(height: context.hp(2)),
            Text(
              'Could not load profile',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: context.sp(16),
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              e.toString(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: context.sp(12),
                color: AppColors.greyDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.hp(1)),
            TextButton(
              onPressed: () => ref.refresh(profileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top section ───────────────────────────────────────────────────────────────

class _TopSection extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onLogout;
  const _TopSection({required this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final blobSize = context.wp(52);
    final displayName = profile.name.isNotEmpty ? profile.name : profile.username;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -context.hp(1.5),
          right: -context.wp(12),
          child: Container(
            width: blobSize,
            height: blobSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.wp(4),
              context.hp(1.5),
              context.wp(4),
              context.hp(2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'lib/assets/idli-icon.png',
                  height: context.sp(34),
                  fit: BoxFit.contain,
                ),
                SizedBox(height: context.hp(2)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Avatar(avatarUrl: profile.avatar, size: context.wp(9)),
                    SizedBox(width: context.wp(3.5)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: context.sp(18),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dark,
                                    height: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (profile.isVerified) ...[
                                SizedBox(width: context.wp(1.5)),
                                Icon(
                                  Icons.verified_rounded,
                                  size: context.sp(16),
                                  color: AppColors.primary,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: context.hp(0.3)),
                          Text(
                            '@${profile.username}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: context.sp(12),
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (profile.bio.isNotEmpty) ...[
                            SizedBox(height: context.hp(0.7)),
                            Text(
                              profile.bio,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: context.sp(12),
                                color: AppColors.dark.withValues(alpha: 0.75),
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: context.wp(1)),
                    Image.asset(
                      'lib/assets/favicon.png',
                      width: context.wp(24),
                      height: context.hp(17),
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  const _Avatar({required this.avatarUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: size,
        backgroundColor: AppColors.grey.withValues(alpha: 0.25),
        child: ClipOval(
          child: avatarUrl != null
              ? Image.network(
                  avatarUrl!,
                  width: size * 2,
                  height: size * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    color: AppColors.greyDark,
                    size: size * 0.9,
                  ),
                )
              : Icon(
                  Icons.person,
                  color: AppColors.greyDark,
                  size: size * 0.9,
                ),
        ),
      ),
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final UserProfile profile;
  const _StatsCard({required this.profile});

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.hp(1.8)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(value: _fmt(profile.totalPost), label: AppData.profilePostsLabel),
          _StatDivider(),
          _StatItem(value: _fmt(profile.totalLikes), label: AppData.profileLikesLabel),
          _StatDivider(),
          _StatItem(value: _fmt(profile.totalStars), label: AppData.profileStarsLabel),
          _StatDivider(),
          _StatItem(
            value: _fmt(profile.totalRating),
            label: AppData.profileRatingLabel,
            showStar: true,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool showStar;

  const _StatItem({
    required this.value,
    required this.label,
    this.showStar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStar)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, size: context.sp(14), color: AppColors.accent),
                SizedBox(width: context.wp(0.8)),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                    height: 1.2,
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: context.sp(16),
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
                height: 1.2,
              ),
            ),
          SizedBox(height: context.hp(0.4)),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(11),
              color: AppColors.greyDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: context.hp(4.5),
      color: AppColors.grey.withValues(alpha: 0.3),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final WidgetRef ref;
  final UserProfile profile;
  const _ActionButtons({required this.ref, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 55,
          child: SizedBox(
            height: context.hp(5.5),
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompleteProfileScreen(profile: profile),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                AppData.profileEditBtn,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: context.wp(2.5)),
        Expanded(
          flex: 40,
          child: SizedBox(
            height: context.hp(5.5),
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dark,
                side: BorderSide(
                  color: AppColors.grey.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                AppData.profileShareBtn,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Profile completion banner ─────────────────────────────────────────────────

class _CompletionBanner extends StatelessWidget {
  final UserProfile profile;
  const _CompletionBanner({required this.profile});

  static const _fieldLabels = <String, String>{
    'name': 'Name',
    'avatar': 'Profile photo',
    'bio': 'Bio',
    'location': 'Location',
    'diet': 'Diet preference',
    'dob': 'Date of birth',
    'food_preference': 'Food preference',
  };

  @override
  Widget build(BuildContext context) {
    final missing = profile.incompleteFields
        .map((f) => _fieldLabels[f] ?? f)
        .join(', ');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            profile: profile,
            filterToIncomplete: true,
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(4),
          vertical: context.hp(1.5),
        ),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: context.sp(18), color: AppColors.dark),
            SizedBox(width: context.wp(2.5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile ${profile.completionPercentage}% complete',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(13),
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  if (missing.isNotEmpty)
                    Text(
                      'Missing: $missing',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: context.sp(11),
                        color: AppColors.greyDark,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: context.sp(18), color: AppColors.greyDark),
          ],
        ),
      ),
    );
  }
}

// ── Highlights ────────────────────────────────────────────────────────────────

class _HighlightsSection extends StatelessWidget {
  const _HighlightsSection();

  @override
  Widget build(BuildContext context) {
    final circleSize = context.wp(14).clamp(50.0, 68.0);
    final rowHeight = circleSize + 5 + context.sp(10) * 2.3 + 10;

    return SizedBox(
      height: rowHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _NewHighlight(circleSize: circleSize),
          SizedBox(width: context.wp(3.5)),
          ...AppData.profileHighlights.map(
            (h) => Padding(
              padding: EdgeInsets.only(right: context.wp(3.5)),
              child: _HighlightChip(
                emoji: h['emoji']!,
                name: h['name']!,
                circleSize: circleSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewHighlight extends StatelessWidget {
  final double circleSize;
  const _NewHighlight({required this.circleSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2.5),
            color: AppColors.background,
          ),
          child: Center(
            child: Container(
              width: circleSize * 0.48,
              height: circleSize * 0.48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
              child: Icon(Icons.add, size: circleSize * 0.28, color: AppColors.dark),
            ),
          ),
        ),
        SizedBox(height: context.hp(0.5)),
        SizedBox(
          width: circleSize + context.wp(2),
          child: Text(
            AppData.profileNewHighlight,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(10),
              height: 1.15,
              color: AppColors.greyDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _HighlightChip extends StatelessWidget {
  final String emoji;
  final String name;
  final double circleSize;

  const _HighlightChip({
    required this.emoji,
    required this.name,
    required this.circleSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFCB7A), Color(0xFFFF8C38)],
            ),
          ),
          child: Center(
            child: Text(emoji, style: TextStyle(fontSize: context.sp(24))),
          ),
        ),
        SizedBox(height: context.hp(0.5)),
        SizedBox(
          width: circleSize + context.wp(2),
          child: Text(
            name,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(10),
              height: 1.15,
              color: AppColors.greyDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Posts grid ────────────────────────────────────────────────────────────────

class _PostsGrid extends StatelessWidget {
  final List<ProfilePost> posts;
  const _PostsGrid({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFF555555),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 0.5,
          mainAxisSpacing: 0.5,
          childAspectRatio: 1.0,
        ),
        itemCount: posts.length,
        itemBuilder: (_, i) => Image.network(
          posts[i].thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => AppShimmer(borderRadius: BorderRadius.zero),
        ),
      ),
    );
  }
}

// ── Logout ────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
      child: SizedBox(
        width: double.infinity,
        height: context.hp(6),
        child: TextButton(
          onPressed: onLogout,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.red.shade200, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: context.sp(18)),
              SizedBox(width: context.wp(2)),
              Text(
                AppData.profileLogoutBtn,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
