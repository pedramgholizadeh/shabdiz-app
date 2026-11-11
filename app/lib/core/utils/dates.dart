import 'package:shamsi_date/shamsi_date.dart';

abstract final class Dates {
  // Iran has used a fixed UTC+03:30 offset since the 2022 DST abolition.
  static const _tehranOffset = Duration(hours: 3, minutes: 30);

  static Jalali toTehranJalali(DateTime utc) =>
      Jalali.fromDateTime(utc.toUtc().add(_tehranOffset));

  static String jalaliDate(DateTime utc) {
    final date = toTehranJalali(utc);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String jalaliDateTime(DateTime utc) {
    final local = utc.toUtc().add(_tehranOffset);
    final date = Jalali.fromDateTime(local);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${date.day} ${date.formatter.mN} · $hour:$minute';
  }

  static String faDigits(String input) {
    const western = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var result = input;
    for (var i = 0; i < western.length; i++) {
      result = result.replaceAll(western[i], persian[i]);
    }
    return result;
  }

  static String clock(DateTime utc) {
    final local = utc.toUtc().add(_tehranOffset);
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
