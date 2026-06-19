import 'package:intl/intl.dart';

String formatPrice(num price) {
  final formatter = NumberFormat('#,###');
  return 'Rs. ${formatter.format(price)}';
}

String formatDynamicPrice(Object? price) {
  if (price is num) {
    return formatPrice(price);
  }

  final parsedPrice = num.tryParse(price?.toString() ?? '') ?? 0;
  return formatPrice(parsedPrice);
}
