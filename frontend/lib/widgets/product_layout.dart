import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ui_settings_provider.dart';

int getProductCrossAxisCount(double width, {int? desktopCount}) {
  if (width >= 900) return (desktopCount ?? 6).clamp(2, 6);
  if (width >= 600) return 3;
  return 2;
}

SliverGridDelegateWithFixedCrossAxisCount productGridDelegate(
  double width, {
  BuildContext? context,
}) {
  final desktopCount = context?.watch<UiSettingsProvider>().settings.productsPerRowDesktop;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: getProductCrossAxisCount(width, desktopCount: desktopCount),
    mainAxisSpacing: 18,
    crossAxisSpacing: 18,
    childAspectRatio: 0.72,
  );
}

double getProductCarouselItemWidth(
  double width, {
  int? desktopCount,
}) {
  final visibleItems = getProductCrossAxisCount(width, desktopCount: desktopCount);
  final spacing = visibleItems == 2 ? 12.0 : 18.0;
  return (width - (spacing * (visibleItems - 1))) / visibleItems;
}
