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

  String wrap([int length = 40, bool center = false]) {
    if (this.length <= length) {
      return this;
    }
    return split("")
        .fold<List<String>>([""], (previousValue, element) {
          var currentLine = previousValue.last;
          if (currentLine.length < length) {
            previousValue[previousValue.length - 1] = center
                ? (currentLine + element).center(length)
                : (currentLine + element);
          } else {
            previousValue.add(element);
          }
          return previousValue;
        })
        .join("\n");
  }

  String expand(String item, [int length = 40]) {
    if (this.length + item.length > (length + 1)) {
      return ("$this $item").wrap(length);
    }
    String spaces = " " * (length - this.length - item.length);
    return "$this$spaces$item".wrap(length);
  }

  String center([int length = 40]) {
    if (this.length >= length) {
      return this;
    }
    String padding = " " * ((length - this.length) / 2).floor();
    return "$padding$this".wrap(length, true);
  }
}
