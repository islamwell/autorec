import 'package:flutter/material.dart';

/// Custom gradient widgets for Material Design 3 theming
/// Provides gradient backgrounds, buttons, and containers

// Color constants for gradient widgets
const Color _primaryDark = Color(0xFF1A237E);
const Color _primaryLight = Color(0xFF0D47A1);
const Color _secondaryDark = Color(0xFF4A148C);
const Color _secondaryLight = Color(0xFF6A1B9A);
const Color _accentOrange = Color(0xFFE65100);
const Color _accentOrangeLight = Color(0xFFFF6F00);
const Color _surfaceDark = Color(0xFF121212);
const Color _surfaceLight = Color(0xFF1E1E1E);

// Gradient definitions
const LinearGradient _primaryGradient = LinearGradient(
  colors: [_primaryDark, _primaryLight],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient _secondaryGradient = LinearGradient(
  colors: [_secondaryDark, _secondaryLight],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient _accentGradient = LinearGradient(
  colors: [_accentOrange, _accentOrangeLight],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient _surfaceGradient = LinearGradient(
  colors: [_surfaceDark, _surfaceLight],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

/// Gradient container with rounded corners and shadows
class GradientContainer extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final double borderRadius;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GradientContainer({
    Key? key,
    required this.child,
    this.gradient,
    this.borderRadius = 16,
    this.elevation = 8,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ?? _surfaceGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

/// Gradient elevated button with custom styling
class GradientElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final LinearGradient? gradient;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double elevation;

  const GradientElevatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.borderRadius = 24,
    this.padding,
    this.elevation = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? _primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Large circular gradient button for primary actions (like recording)
class GradientCircularButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final LinearGradient? gradient;
  final double size;
  final double elevation;

  const GradientCircularButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.size = 80,
    this.elevation = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? _accentGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Gradient card with Material Design 3 styling
class GradientCard extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final double borderRadius;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GradientCard({
    Key? key,
    required this.child,
    this.gradient,
    this.borderRadius = 16,
    this.elevation = 8,
    this.padding,
    this.margin,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: gradient ?? _surfaceGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
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
  }
}

/// Gradient progress bar with thick styling (8dp)
class GradientProgressBar extends StatelessWidget {
  final double value;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;

  const GradientProgressBar({
    Key? key,
    required this.value,
    this.gradient,
    this.backgroundColor,
    this.height = 8,
    this.borderRadius = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white24,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            gradient != null ? _accentOrange : Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}

/// Gradient app bar with custom styling
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final LinearGradient? gradient;
  final List<Widget>? actions;
  final Widget? leading;
  final double elevation;

  const GradientAppBar({
    Key? key,
    required this.title,
    this.gradient,
    this.actions,
    this.leading,
    this.elevation = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? _primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: actions,
        leading: leading,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Gradient bottom navigation bar
class GradientBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final LinearGradient? gradient;
  final double elevation;

  const GradientBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.gradient,
    this.elevation = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? _surfaceGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: elevation,
            offset: Offset(0, -elevation / 2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _accentOrange,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}