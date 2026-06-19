import 'package:flutter/material.dart';

int getProductCrossAxisCount(double width) {
  if (width >= 1200) return 6;
  if (width >= 900) return 4;
  if (width >= 600) return 3;
  return 2;
}

SliverGridDelegateWithFixedCrossAxisCount productGridDelegate(double width) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: getProductCrossAxisCount(width),
    mainAxisSpacing: 18,
    crossAxisSpacing: 18,
    childAspectRatio: 0.72,
  );
}

double getProductCarouselItemWidth(double width) {
  final visibleItems = getProductCrossAxisCount(width);
  final spacing = visibleItems == 2 ? 12.0 : 18.0;
  return (width - (spacing * (visibleItems - 1))) / visibleItems;
}
