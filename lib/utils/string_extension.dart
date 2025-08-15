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

  String toPrinter([int length = 40]) {
    if (this.length <= 40) {
      return this;
    }
    return this.substring(0, length);
  }
}
