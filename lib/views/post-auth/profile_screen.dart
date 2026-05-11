import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_shimmer.dart';
import '../pre-auth/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopSection(onLogout: () => _logout(context)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.hp(2.5)),
                  const _StatsCard(),
                  SizedBox(height: context.hp(2)),
                  const _ActionButtons(),
                  SizedBox(height: context.hp(2.5)),
                  const _HighlightsSection(),
                ],
              ),
            ),
            SizedBox(height: context.hp(1.5)),
            const _PostsGrid(),
            SizedBox(height: context.hp(2)),
            _LogoutButton(onLogout: () => _logout(context)),
            SizedBox(height: context.hp(4)),
          ],
        ),
      ),
    );
  }
}

// ── Top section: blob + logo + profile row with mascot ────────────────────────

class _TopSection extends StatelessWidget {
  final VoidCallback onLogout;
  const _TopSection({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final blobSize = context.wp(52);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Yellow circle — top-right, ~half off-screen
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
                // Logo
                Image.asset(
                  'lib/assets/idli-icon.png',
                  height: context.sp(34),
                  fit: BoxFit.contain,
                ),

                SizedBox(height: context.hp(2)),

                // Profile row: avatar | info | mascot
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
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
                        radius: context.wp(9),
                        backgroundColor: AppColors.grey.withValues(alpha: 0.25),
                        child: Icon(
                          Icons.person,
                          color: AppColors.greyDark,
                          size: context.sp(28),
                        ),
                      ),
                    ),

                    SizedBox(width: context.wp(3.5)),

                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppData.profileUserName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: context.sp(18),
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: context.hp(0.3)),
                          Text(
                            AppData.profileHandle,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: context.sp(12),
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: context.hp(0.7)),
                          Text(
                            AppData.profileBioText,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: context.sp(12),
                              color: AppColors.dark.withValues(alpha: 0.75),
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: context.hp(0.7)),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: context.sp(13),
                                color: AppColors.primary,
                              ),
                              SizedBox(width: context.wp(1)),
                              Flexible(
                                child: Text(
                                  AppData.profileLocationText,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: context.sp(12),
                                    color: AppColors.greyDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: context.wp(1)),

                    // Mascot — right of info
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

// ── Stats card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard();

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
          _StatItem(
            value: AppData.profilePostsCount,
            label: AppData.profilePostsLabel,
          ),
          _StatDivider(),
          _StatItem(
            value: AppData.profileLikesCount,
            label: AppData.profileLikesLabel,
          ),
          _StatDivider(),
          _StatItem(
            value: AppData.profileStarsCount,
            label: AppData.profileStarsLabel,
          ),
          _StatDivider(),
          _StatItem(
            value: AppData.profileRatingValue,
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
                Icon(
                  Icons.star_rounded,
                  size: context.sp(14),
                  color: AppColors.accent,
                ),
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
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 55,
          child: SizedBox(
            height: context.hp(5.5),
            child: ElevatedButton(
              onPressed: () {},
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
              child: Icon(
                Icons.add,
                size: circleSize * 0.28,
                color: AppColors.dark,
              ),
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
            child: Text(
              emoji,
              style: TextStyle(fontSize: context.sp(24)),
            ),
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
  const _PostsGrid();

  @override
  Widget build(BuildContext context) {
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
        itemCount: 12,
        itemBuilder: (_, __) => AppShimmer(borderRadius: BorderRadius.zero),
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
