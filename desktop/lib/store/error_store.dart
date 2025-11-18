import "package:rxdart/rxdart.dart";

class SysNotification {
  bool show;
  String title;
  String message;
  SysNotification({required this.show, this.title = "", this.message = ""});
}

class ErrorStore {
  static ErrorStore? _instance;
  late BehaviorSubject<SysNotification> _obs;
  ErrorStore._() {
    _obs = BehaviorSubject.seeded(SysNotification(show: false));
  }
  static ErrorStore get instance {
    _instance ??= ErrorStore._();
    return _instance!;
  }

  Stream<SysNotification> get stream => _obs;
  ErrorStore update(SysNotification notification) {
    _obs.add(notification);
    return this;
  }
}
