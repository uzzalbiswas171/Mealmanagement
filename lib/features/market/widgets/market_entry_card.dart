import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/market_entry_model.dart';

class MarketEntryCard extends StatelessWidget {
  final MarketEntry entry;
  final VoidCallback? onTap;

  const MarketEntryCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppSpacing.cardBorderRadius,
        boxShadow: const [AppSpacing.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: AppTextStyles.headingSmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.formattedAmount,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Date + Status badge
          Row(
            children: [
              Expanded(
                child: Text(entry.dateLabel, style: AppTextStyles.metaText),
              ),
              _StatusBadge(status: entry.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          // Tags
          _TagsRow(tags: entry.tags),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          // Made by
          if (entry.createdByName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Made by: ${entry.createdByName}',
                    style: AppTextStyles.metaText.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          // Footer: avatars + verified text
          Row(
            children: [
              _OverlappingAvatars(avatarUrls: entry.verifierAvatarUrls),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.verifiedLabel,
                  style: AppTextStyles.metaText,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MarketEntryStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case MarketEntryStatus.completed:
        bg = AppColors.greenLight;
        fg = AppColors.greenAccent;
        break;
      case MarketEntryStatus.archived:
        bg = const Color(0xFFEEEEEE);
        fg = AppColors.textSecondary;
        break;
      case MarketEntryStatus.pending:
        bg = AppColors.redLight;
        fg = AppColors.redAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.badgeText.copyWith(color: fg),
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  final List<String> tags;
  const _TagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map((tag) => _TagChip(label: tag)).toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.greySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Text(label, style: AppTextStyles.metaText.copyWith(fontSize: 12)),
    );
  }
}

class _OverlappingAvatars extends StatelessWidget {
  final List<String> avatarUrls;
  const _OverlappingAvatars({required this.avatarUrls});

  @override
  Widget build(BuildContext context) {
    const double size = 28;
    const double overlap = 10;
    final count = avatarUrls.length;
    if (count == 0) return const SizedBox(width: size, height: size);
    final totalWidth = size + (count - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrls[i],
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(
                    color: AppColors.blueSurface,
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  errorWidget: (ctx, url, err) => Container(
                    color: AppColors.blueSurface,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
