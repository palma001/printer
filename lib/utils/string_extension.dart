extension StringExtension on String {
  String ljust(int length, [String padString = " "]) {
    if (this.length >= length) {
      return this;
    }
    return this + padString * (length - this.length);
  }

  String rjust(int length, [String padString = " "]) {
    if (this.length >= length) {
      return this;
    }
    return padString * (length - this.length) + this;
  }
}
