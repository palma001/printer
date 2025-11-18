class Printer {
  String name;
  String identifier;
  String type;
  Printer({this.name = "", this.identifier = "", this.type = ""});
  Map<String, dynamic> toMap() {
    return {"name": name, "identifier": identifier, "type": type};
  }
}
