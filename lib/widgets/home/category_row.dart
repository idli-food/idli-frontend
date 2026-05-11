import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';

class CategoryRow extends StatefulWidget {
  const CategoryRow({super.key});

  @override
  State<CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<CategoryRow> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final chipSize = context.wp(14).clamp(50.0, 68.0);
    // Row height = chip + 5px gap + 2-line label (sp(10)*1.15*2) + 10px safety buffer.
    // No vertical padding on ListView so items get the full SizedBox height.
    final rowHeight = chipSize + 5 + context.sp(10) * 2.3 + 10;

    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
        itemCount: AppData.feedCategories.length,
        separatorBuilder: (_, __) => SizedBox(width: context.wp(3.5)),
        itemBuilder: (ctx, i) {
          final cat = AppData.feedCategories[i];
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: _CategoryChip(
              emoji: cat['emoji']!,
              name: cat['name']!,
              isActive: _selected == i,
              chipSize: chipSize,
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String emoji;
  final String name;
  final bool isActive;
  final double chipSize;

  const _CategoryChip({
    required this.emoji,
    required this.name,
    required this.isActive,
    required this.chipSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: chipSize,
          height: chipSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFCB7A), Color(0xFFFF8C38)],
            ),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.white,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isActive ? AppColors.primary : Colors.black)
                    .withValues(alpha: isActive ? 0.25 : 0.08),
                blurRadius: isActive ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
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
          width: chipSize + context.wp(2),
          child: Text(
            name,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(10),
              height: 1.15,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primary : AppColors.greyDark,
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
