import 'package:flutter/material.dart';

class NeumorphicTheme {
  // Color palette
  static const Color background = Color(0xFFE0E5EC);
  static const Color surface = Color(0xFFE0E5EC);
  static const Color darkShadow = Color(0xFFA3B1C6);
  static const Color lightShadow = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF6C63FF);
  static const Color accentLight = Color(0xFF9D97FF);
  static const Color textPrimary = Color(0xFF2E3A59);
  static const Color textSecondary = Color(0xFF6B7A99);
  
  // Spacing
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  
  // Shadow offsets
  static const double shadowOffset = 8.0;
  static const double shadowBlur = 16.0;
  
  // Build neumorphic container (elevated/convex)
  static BoxDecoration elevated({
    double borderRadius = radiusMedium,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: const [
        BoxShadow(
          color: darkShadow,
          offset: Offset(shadowOffset, shadowOffset),
          blurRadius: shadowBlur,
        ),
        BoxShadow(
          color: lightShadow,
          offset: Offset(-shadowOffset, -shadowOffset),
          blurRadius: shadowBlur,
        ),
      ],
    );
  }
  
  // Build neumorphic container (pressed/concave)
  static BoxDecoration pressed({
    double borderRadius = radiusMedium,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: darkShadow.withOpacity(0.5),
          offset: const Offset(-shadowOffset / 2, -shadowOffset / 2),
          blurRadius: shadowBlur / 2,
        ),
        BoxShadow(
          color: lightShadow.withOpacity(0.5),
          offset: const Offset(shadowOffset / 2, shadowOffset / 2),
          blurRadius: shadowBlur / 2,
        ),
      ],
    );
  }
  
  // Build flat neumorphic (subtle)
  static BoxDecoration flat({
    double borderRadius = radiusMedium,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: darkShadow.withOpacity(0.3),
          offset: const Offset(4, 4),
          blurRadius: 8,
        ),
        BoxShadow(
          color: lightShadow.withOpacity(0.8),
          offset: const Offset(-4, -4),
          blurRadius: 8,
        ),
      ],
    );
  }
}

// Neumorphic Button Widget
class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsets padding;
  final bool isSelected;
  
  const NeumorphicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = NeumorphicTheme.radiusMedium,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.isSelected = false,
  });
  
  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: widget.padding,
        decoration: _isPressed || widget.isSelected
            ? NeumorphicTheme.pressed(borderRadius: widget.borderRadius)
            : NeumorphicTheme.elevated(borderRadius: widget.borderRadius),
        child: widget.child,
      ),
    );
  }
}

// Neumorphic Card Widget
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  
  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = NeumorphicTheme.radiusLarge,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: NeumorphicTheme.elevated(borderRadius: borderRadius),
      child: child,
    );
  }
}
