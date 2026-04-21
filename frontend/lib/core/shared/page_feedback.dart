import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PageFeedbackCard extends StatelessWidget {
  const PageFeedbackCard({
    required this.message,
    this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.tone = PageFeedbackTone.neutral,
    super.key,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final PageFeedbackTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _feedbackColors(context, tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon ?? _defaultIcon(tone), color: colors.foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colors.foreground,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum PageFeedbackTone {
  neutral,
  success,
  warning,
  error,
}

class _FeedbackColors {
  const _FeedbackColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}

IconData _defaultIcon(PageFeedbackTone tone) {
  return switch (tone) {
    PageFeedbackTone.neutral => Icons.info_outline,
    PageFeedbackTone.success => Icons.check_circle_outline,
    PageFeedbackTone.warning => Icons.warning_amber_outlined,
    PageFeedbackTone.error => Icons.error_outline,
  };
}

_FeedbackColors _feedbackColors(BuildContext context, PageFeedbackTone tone) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return switch (tone) {
    PageFeedbackTone.neutral => _FeedbackColors(
        background: isDark ? AppColors.neutral800 : AppColors.neutral50,
        border: isDark ? AppColors.neutral600 : AppColors.neutral200,
        foreground: isDark ? AppColors.neutral50 : AppColors.neutral950,
      ),
    PageFeedbackTone.success => _FeedbackColors(
        background: isDark
            ? AppColors.accentDark.withOpacity(0.20)
            : AppColors.accentLight,
        border: isDark
            ? AppColors.accentLight.withOpacity(0.26)
            : AppColors.accent.withOpacity(0.26),
        foreground: isDark ? AppColors.accentLight : AppColors.accentDark,
      ),
    PageFeedbackTone.warning => _FeedbackColors(
        background: AppColors.warning.withOpacity(isDark ? 0.16 : 0.10),
        border: AppColors.warning.withOpacity(isDark ? 0.30 : 0.22),
        foreground: isDark ? Colors.white : AppColors.neutral950,
      ),
    PageFeedbackTone.error => _FeedbackColors(
        background: AppColors.error.withOpacity(isDark ? 0.14 : 0.08),
        border: AppColors.error.withOpacity(isDark ? 0.28 : 0.20),
        foreground: isDark ? Colors.white : AppColors.error,
      ),
  };
}
