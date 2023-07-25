class Helper {
  static String statusCheck(int value, String text) {
    String result = 'Unknown value: $value';
    if(value > 0 && value < 254) {
      result = '$text finished & error';
    } else if(value >= 254 && value <= 255) {
      result = text.replaceAll('e', 'ing');
    }
    return result;
  }

  static String numberExtractor(String number) {
    return number.replaceAll(RegExp(r'[^0-9]'),'');
  }
}