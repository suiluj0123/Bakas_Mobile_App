class SessionService {
  static final SessionService _instance = SessionService._internal();

  factory SessionService() {
    return _instance;
  }

  SessionService._internal();

  int? _playerId;
  String? _firstName;

  int? get playerId => _playerId;
  String? get firstName => _firstName;

  void saveSession({int? playerId, String? firstName}) {
    _playerId = playerId;
    _firstName = firstName;
  }

  void clearSession() {
    _playerId = null;
    _firstName = null;
  }
}
