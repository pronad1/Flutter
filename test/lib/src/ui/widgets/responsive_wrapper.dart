import 'package:flutter/material.dart';

/// Responsive wrapper that constrains content width on large screens (web)
/// Keeps mobile-like width on desktop for better UX
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool centerContent;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // On mobile/tablet, show full width
    if (screenWidth <= 800) {
      return child;
    }
    
    // On desktop, constrain width and center
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Responsive grid for item lists
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);
    
    if (crossAxisCount == 1) {
      return ListView.separated(
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => children[i],
      );
    }
    
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: children.length,
      itemBuilder: (context, i) => children[i],
    );
  }
}

/// Helper to get responsive padding
EdgeInsets getResponsivePadding(BuildContext context, {double mobile = 16, double desktop = 24}) {
  final screenWidth = MediaQuery.of(context).size.width;
  return EdgeInsets.all(screenWidth > 800 ? desktop : mobile);
}

/// Helper to get number of columns for grid
int getGridColumns(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  return screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);
}
