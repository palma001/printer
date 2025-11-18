import "package:rxdart/rxdart.dart";

enum AppStatus {
  connecting,
  connected,
  disconnected,
  receiving,
  error,
  sendingPrinters,
  printing,
}

class AppMainState {
  final AppStatus status;
  final String? message;
  const AppMainState({required this.status, this.message});
}

class AppMainStore {
  static AppMainStore? _instance;
  late BehaviorSubject<AppMainState> _obs;
  AppMainStore._() {
    _obs = BehaviorSubject.seeded(
      const AppMainState(
        status: AppStatus.disconnected,
        message: "Disconnected",
      ),
    );
  }
  static AppMainStore get instance {
    _instance ??= AppMainStore._();
    return _instance!;
  }

  Stream<AppMainState> get stream => _obs.stream;

  AppMainStore update(AppMainState state) {
    _obs.add(state);
    return this;
  }

  AppMainStore mapUpdate(AppMainState Function(AppMainState) mapper) {
    _obs.add(mapper(_obs.value));
    return this;
  }
}
