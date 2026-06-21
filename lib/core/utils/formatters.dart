import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    }
    return DateFormat('dd/MM/yy').format(dateTime);
  }

  static String phoneDisplay(String phone) {
    if (phone.length >= 10) {
      final last4 = phone.substring(phone.length - 4);
      final country = phone.length > 10 ? phone.substring(0, phone.length - 10) : '';
      return '${country}XXXXXX$last4';
    }
    return phone;
  }
}
