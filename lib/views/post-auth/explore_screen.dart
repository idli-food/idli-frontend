import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_shimmer.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Unified search bar ──────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.hp(1.4),
              ),
              child: _UnifiedSearchBar(controller: _searchController),
            ),
          ),

          // ── Shimmer grid ────────────────────────────────────────────────
          const Expanded(child: _ExploreGrid()),
        ],
      ),
    );
  }
}

// ── Unified search + filter pill ─────────────────────────────────────────────

class _UnifiedSearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _UnifiedSearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(6.2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          // ── Left: search input ──────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                SizedBox(width: context.wp(4)),
                Icon(
                  Icons.search_rounded,
                  color: AppColors.grey,
                  size: context.sp(20),
                ),
                SizedBox(width: context.wp(2)),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(13),
                      color: AppColors.dark,
                    ),
                    decoration: InputDecoration(
                      hintText: AppData.exploreSearchHint,
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: context.sp(13),
                        color: AppColors.grey,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Vertical divider ─────────────────────────────────────────
          Container(
            width: 1,
            height: context.hp(3),
            color: AppColors.primary,
            margin: EdgeInsets.symmetric(horizontal: context.wp(2)),
          ),

          // ── Right: place filter ───────────────────────────────────────
          GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(right: context.wp(4)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: context.sp(14),
                  ),
                  SizedBox(width: context.wp(1)),
                  Text(
                    AppData.exploreSearchByPlace,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(12),
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: context.wp(0.5)),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.greyDark,
                    size: context.sp(16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3 × 12 shimmer grid ───────────────────────────────────────────────────────

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid();

  @override
  Widget build(BuildContext context) {
    return Container(
      // Dark gap colour — shows through 0.5px spacing as thin grid lines
      color: const Color(0xFF555555),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 0.5,
          mainAxisSpacing: 0.5,
          childAspectRatio: 1.0,
        ),
        itemCount: 36,
        itemBuilder: (_, __) => const _ShimmerCell(),
      ),
    );
  }
}

class _ShimmerCell extends StatelessWidget {
  const _ShimmerCell();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(borderRadius: BorderRadius.zero);
  }
}
