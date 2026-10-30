import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final Border? border;
  final double borderRadius;
  final Gradient? gradient;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.border,
    this.borderRadius = 16,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final defaultBorder = isDark
        ? const BorderSide(color: Color(0xFF334155), width: 1)
        : const BorderSide(color: Color(0xFFE2E8F0), width: 1);

    final resolvedColor = gradient == null ? (color ?? defaultBg) : null;

    Widget cardBody = Container(
      decoration: BoxDecoration(
        color: resolvedColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: gradient == null ? (border ?? Border.fromBorderSide(defaultBorder)) : null,
        boxShadow: isDark || gradient != null
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: cardBody,
      );
    }

    return cardBody;
  }
}
