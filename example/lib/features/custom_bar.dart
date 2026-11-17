import 'dart:ui';

import 'package:flutter/material.dart';

class CustomBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomBar({
    super.key,
    this.title = 'Dashboard',
    this.subtitle = 'Welcome Back',
    this.primaryColor = const Color(0xFF4A00E0),
    this.secondaryColor = const Color(0xFF8E2DE2),
    this.accentColor = const Color(0xFFFFD700),
    this.textColor = Colors.white,
    this.leftIcon,
    this.onBackTapped,
    this.firstIcon,
    this.secondIcon,
    this.onFirstCalled,
    this.onSecondCalled,
    this.hasUnreadNotifications = true,
  });

  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color textColor;
  final IconData? leftIcon;
  final VoidCallback? onBackTapped;
  final IconData? firstIcon;
  final IconData? secondIcon;
  final VoidCallback? onFirstCalled;
  final VoidCallback? onSecondCalled;
  final bool hasUnreadNotifications;

  @override
  State<CustomBar> createState() => _CustomBarState();

  @override
  Size get preferredSize => const Size.fromHeight(112);
}

class _CustomBarState extends State<CustomBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _liquidController;

  @override
  void initState() {
    super.initState();
    _liquidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _liquidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leftIcon = widget.leftIcon;
    final firstIcon = widget.firstIcon;
    final secondIcon = widget.secondIcon;
    final showBackButton = leftIcon != null || widget.onBackTapped != null;
    final showFirstButton = firstIcon != null || widget.onFirstCalled != null;
    final showSecondButton =
        secondIcon != null || widget.onSecondCalled != null;

    return AnimatedBuilder(
      animation: _liquidController,
      builder: (context, child) {
        return ClipPath(
          clipper: _CustomBarClipper(animationValue: _liquidController.value),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.primaryColor.withValues(alpha: 0.90),
                    widget.secondaryColor.withValues(alpha: 0.90),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (showBackButton) ...[
                              _GlassButton(
                                icon: leftIcon ?? Icons.more_horiz_rounded,
                                textColor: widget.textColor,
                                onTap:
                                    widget.onBackTapped ??
                                    () => Navigator.maybePop(context),
                              ),
                              const SizedBox(width: 14),
                            ],
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.subtitle.isNotEmpty)
                                    Text(
                                      widget.subtitle.toUpperCase(),
                                      style: TextStyle(
                                        color: widget.textColor.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      color: widget.textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showFirstButton || showSecondButton) ...[
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showFirstButton)
                              _GlassButton(
                                icon: firstIcon ?? Icons.more_horiz_rounded,
                                textColor: widget.textColor,
                                onTap: widget.onFirstCalled,
                              ),
                            if (showFirstButton && showSecondButton)
                              const SizedBox(width: 8),
                            if (showSecondButton)
                              _GlassButton(
                                icon: secondIcon ?? Icons.more_horiz_rounded,
                                textColor: widget.textColor,
                                hasBadge:
                                    secondIcon != null &&
                                    widget.hasUnreadNotifications,
                                badgeColor: widget.accentColor,
                                onTap: widget.onSecondCalled,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.textColor,
    this.onTap,
    this.hasBadge = false,
    this.badgeColor = Colors.amber,
  });

  final IconData icon;
  final Color textColor;
  final VoidCallback? onTap;
  final bool hasBadge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: textColor.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: textColor, size: 20),
                  if (hasBadge)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomBarClipper extends CustomClipper<Path> {
  _CustomBarClipper({required this.animationValue});
  final double animationValue;

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);

    final controlPointX = size.width * (0.3 + (animationValue * 0.4));
    final controlPointY = size.height + (18 * (animationValue - 0.5) * 2);

    path.quadraticBezierTo(
      controlPointX,
      controlPointY,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CustomBarClipper oldClipper) {
    return oldClipper.animationValue != animationValue;
  }
}
