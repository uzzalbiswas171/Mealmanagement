import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';

enum AppHeaderAction { bell, search, profile }

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final AppHeaderAction action;
  final VoidCallback? onActionTap;
  final VoidCallback? onAvatarTap;

  const AppHeader({
    super.key,
    this.action = AppHeaderAction.bell,
    this.onActionTap,
    this.onAvatarTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  static String _initials(String displayName) {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.primaryBlue,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text('Meal Manager', style: AppTextStyles.appBarTitle),
              const Spacer(),
              if (action == AppHeaderAction.bell) _BellIcon(onTap: onActionTap),
              if (action == AppHeaderAction.search)
                IconButton(
                  onPressed: onActionTap,
                  icon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              if (action == AppHeaderAction.profile)
                IconButton(
                  onPressed: onActionTap,
                  icon: const Icon(
                    Icons.account_circle_outlined,
                    color: AppColors.textPrimary,
                    size: 26,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    _initials(context.read<AppState>().displayName ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _BellIcon extends StatelessWidget {
  final VoidCallback? onTap;
  const _BellIcon({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
