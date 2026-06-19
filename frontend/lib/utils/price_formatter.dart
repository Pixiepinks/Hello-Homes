import 'package:intl/intl.dart';

String formatPrice(num price, {String currencySymbol = 'Rs.'}) {
  final formatter = NumberFormat('#,###');
  return '$currencySymbol ${formatter.format(price)}';
}

String formatDynamicPrice(Object? price, {String currencySymbol = 'Rs.'}) {
  if (price is num) {
    return formatPrice(price, currencySymbol: currencySymbol);
  }

  final parsedPrice = num.tryParse(price?.toString() ?? '') ?? 0;
  return formatPrice(parsedPrice, currencySymbol: currencySymbol);
}
