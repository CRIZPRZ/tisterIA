import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/mock_data.dart';
import '../models/chat.dart';
import '../models/pick.dart';
import '../services/accuracy_service.dart';
import '../services/ads_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/iap_service.dart';
import '../services/notifications_service.dart';
import '../services/picks_service.dart';
import '../services/push_service.dart';
import '../services/usage_service.dart';

/// Dev-only: cuando es true, ningún pick se bloquea sin importar el plan.
/// Ponlo en false para probar el flujo real de paywall.
const bool kDevUnlockAll = false;

/// Dev-only: simula que la carga de picks falla por red, para previsualizar
/// el estado de error. Déjalo en false en desarrollo normal.
const bool kSimulateNetworkError = false;

enum AppScreen {
  onboarding,
  login,
  signup,
  forgot,
  home,
  detail,
  paywall,
  profile,
  notifications,
  settings,
  onboardingPreferences,
  accuracyHistory,
  privacy,
  leaguePreferences,
  leagues,
  chatPicker,
}

/// Adónde debe volver el botón atrás físico (Android) desde cada pantalla.
/// Null significa "pantalla raíz": el botón atrás sale de la app.
AppScreen? backTargetFor(AppScreen screen) {
  switch (screen) {
    case AppScreen.login:
    case AppScreen.signup:
      return AppScreen.onboarding;
    case AppScreen.forgot:
      return AppScreen.login;
    case AppScreen.detail:
    case AppScreen.paywall:
      return AppScreen.home;
    case AppScreen.notifications:
    case AppScreen.settings:
    case AppScreen.accuracyHistory:
    case AppScreen.leaguePreferences:
      return AppScreen.profile;
    case AppScreen.privacy:
      return AppScreen.settings;
    case AppScreen.onboarding:
    case AppScreen.home:
    case AppScreen.profile:
    case AppScreen.onboardingPreferences:
    case AppScreen.leagues:
    case AppScreen.chatPicker:
      return null;
  }
}

class AppState extends ChangeNotifier {
  AppScreen screen = AppScreen.onboarding;
  String? selectedId;
  String filter = 'all';
  int dayOffset = 0; // 0 = hoy, 1 = mañana, 2 = pasado mañana

  void setDayOffset(int offset) {
    dayOffset = offset;
    notifyListeners();
  }

  String? homeLeagueFilter;

  void setHomeLeagueFilter(String? league) {
    homeLeagueFilter = league;
    notifyListeners();
  }

  String get selectedDate {
    final d = DateTime.now().add(Duration(days: dayOffset));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
  String plan = 'free';
  bool forgotSent = false;

  List<Pick> allPicks = [];

  Future<bool> loadPicks() async {
    try {
      allPicks = await PicksService.instance.fetchPicks();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Pick> picksForMatch(String teamA, String teamB, String time) =>
      allPicks.where((p) => p.teamA == teamA && p.teamB == teamB && p.time == time).toList();

  AccuracySummary? accuracy;
  bool accuracyLoading = false;
  bool accuracyError = false;

  Future<void> loadAccuracy() async {
    accuracyLoading = true;
    accuracyError = false;
    notifyListeners();
    try {
      accuracy = await AccuracyService.instance.fetchAccuracy();
    } catch (_) {
      accuracyError = true;
    } finally {
      accuracyLoading = false;
      notifyListeners();
    }
  }

  bool isBootstrapping = true;
  AuthUser? currentUser;
  bool authLoading = false;
  String? authError;
  String? iapError;
  String? quotaMessage;

  void clearQuotaMessage() {
    quotaMessage = null;
    pendingPickId = null;
    notifyListeners();
  }

  AppState() {
    IapService.instance.onPlanUpdated = (p) {
      plan = p;
      notifyListeners();
    };
    IapService.instance.onError = (msg) {
      iapError = msg;
      notifyListeners();
    };
    IapService.instance.startListening();
    AdsService.instance.init();
    _bootstrap();
  }

  void clearIapError() {
    iapError = null;
    notifyListeners();
  }

  Future<void> _bootstrap() async {
    final user = await AuthService.instance.tryRestoreSession();
    currentUser = user;
    isBootstrapping = false;
    if (user != null) {
      screen = AppScreen.home;
      _afterAuth();
    }
    notifyListeners();
  }

  Future<void> register({required String name, required String email, required String password}) async {
    authLoading = true;
    authError = null;
    notifyListeners();
    try {
      final user = await AuthService.instance.register(name: name, email: email, password: password);
      currentUser = user;
      screen = AppScreen.onboardingPreferences;
      _afterAuth();
    } on AuthException catch (e) {
      authError = e.message;
    } finally {
      authLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    authLoading = true;
    authError = null;
    notifyListeners();
    try {
      final user = await AuthService.instance.login(email: email, password: password);
      currentUser = user;
      screen = AppScreen.home;
      _afterAuth();
    } on AuthException catch (e) {
      authError = e.message;
    } finally {
      authLoading = false;
      notifyListeners();
    }
  }

  /// Se corre una vez que hay sesión activa: trae las preferencias reales
  /// de notificaciones del backend y registra el token de push del
  /// dispositivo. No bloquea la navegación si algo falla.
  Future<void> _afterAuth() async {
    plan = currentUser?.plan ?? 'free';
    await _loadFavoriteLeagues();
    try {
      final prefs = await NotificationsService.instance.fetchPrefs();
      notifPrefs
        ..clear()
        ..addAll(prefs);
      notifyListeners();
    } catch (_) {
      // se queda con los defaults locales si el backend no responde
    }
    PushService.instance.registerForPush();

    // Re-verifica contra Google Play por si la suscripción se canceló o
    // venció desde la última vez que se abrió la app (sin webhooks todavía).
    try {
      final status = await IapService.instance.fetchStatus();
      plan = status.plan;
      notifyListeners();
    } catch (_) {
      // sin conexión con Play o sin suscripción previa — se queda con lo local
    }
  }

  void clearAuthError() {
    authError = null;
    notifyListeners();
  }

  final Map<String, bool> notifPrefs = {
    for (final n in kNotifDefs) n.key: n.key != 'promos',
  };

  final Map<String, List<ChatMessage>> matchChats = {};
  final Set<String> matchChatLoading = {};

  // Guarda por league_id (no por nombre): el nombre mostrado en el selector
  // ("Champions League") no siempre coincide con el nombre que manda la API
  // en cada pick ("UEFA Champions League"), pero el id sí es estable.
  final Set<int> favoriteLeagueIds = {};
  static const _favLeagueIdsKey = 'tipster_favorite_league_ids';
  final FlutterSecureStorage _favLeaguesStorage = const FlutterSecureStorage();

  Future<void> _loadFavoriteLeagues() async {
    final raw = await _favLeaguesStorage.read(key: _favLeagueIdsKey);
    if (raw == null || raw.isEmpty) return;
    favoriteLeagueIds
      ..clear()
      ..addAll(raw.split(',').map(int.parse));
    notifyListeners();
  }

  void toggleFavoriteLeague(int leagueId) {
    if (favoriteLeagueIds.contains(leagueId)) {
      favoriteLeagueIds.remove(leagueId);
    } else {
      favoriteLeagueIds.add(leagueId);
    }
    notifyListeners();
    _favLeaguesStorage.write(key: _favLeagueIdsKey, value: favoriteLeagueIds.join(','));
  }

  void go(AppScreen s) {
    screen = s;
    notifyListeners();
  }

  String? pendingPickId;

  /// Cuota diaria de picks del plan Free: si ya se acabó, manda a Paywall
  /// en vez de abrir el partido. Premium/Pro no tienen límite.
  Future<void> openDetail(String id) async {
    if (plan == 'free') {
      try {
        final result = await UsageService.instance.tryViewPick(id);
        if (!result.allowed) {
          pendingPickId = id;
          quotaMessage = 'Ya viste tus partidos gratis de hoy. Mira un anuncio para ganar 1 más, o hazte Premium para no tener límite.';
          screen = AppScreen.paywall;
          notifyListeners();
          return;
        }
      } catch (_) {
        // si falla la red no bloqueamos al usuario con un candado falso
      }
    }
    selectedId = id;
    screen = AppScreen.detail;
    notifyListeners();
  }

  bool get canWatchAdForBonusPick => AdsService.instance.isReady;

  /// Se llama desde el paywall cuando el usuario tocó "Ver anuncio y ganar
  /// un pick". Si completa el anuncio, suma la cuota y abre el pick que
  /// quería ver originalmente.
  Future<void> watchAdForBonusPick() async {
    await AdsService.instance.show(
      onRewarded: () async {
        try {
          await UsageService.instance.grantBonusPick();
        } catch (_) {
          return;
        }
        final id = pendingPickId;
        clearQuotaMessage();
        if (id != null) await openDetail(id);
      },
      onUnavailable: () {
        quotaMessage = 'No hay anuncio disponible ahora mismo. Intenta de nuevo en un momento.';
        notifyListeners();
      },
    );
  }

  void setFilter(String f) {
    filter = f;
    notifyListeners();
  }

  Future<void> selectPlan(String p) async {
    try {
      final user = await AuthService.instance.setPlan(p);
      currentUser = user;
      plan = user.plan;
    } catch (_) {
      // si falla la red, no cambiamos el plan localmente para no desincronizar con el backend
    }
    screen = AppScreen.home;
    notifyListeners();
  }

  void sendForgot() {
    forgotSent = true;
    notifyListeners();
  }

  void toggleNotif(String key) {
    final newValue = !(notifPrefs[key] ?? false);
    notifPrefs[key] = newValue;
    notifyListeners();
    NotificationsService.instance.updatePrefs({key: newValue}).catchError((_) {
      // si falla, se queda con el valor local; se reintentará la próxima vez
      // que se abra la pantalla y se vuelvan a traer las prefs reales.
    });
  }

  void logout() {
    AuthService.instance.logout();
    currentUser = null;
    plan = 'free';
    filter = 'all';
    forgotSent = false;
    matchChats.clear();
    matchChatLoading.clear();
    _matchChatHistoryLoaded.clear();
    screen = AppScreen.onboarding;
    notifyListeners();
  }

  final Set<String> _matchChatHistoryLoaded = {};

  List<ChatMessage> matchChatFor(Pick p) => matchChats[_matchKey(p)] ?? const [];

  bool isMatchChatLoading(Pick p) => matchChatLoading.contains(_matchKey(p));

  /// Trae el historial guardado del backend la primera vez que se abre el
  /// chat de este partido (una vez por sesión de la app).
  Future<void> loadMatchChatHistory(Pick p) async {
    final key = _matchKey(p);
    if (_matchChatHistoryLoaded.contains(key)) return;
    _matchChatHistoryLoaded.add(key);
    try {
      final history = await ChatService.instance.fetchHistory(p.id);
      if (history.isNotEmpty) {
        matchChats[key] = history;
        notifyListeners();
      }
    } catch (_) {
      _matchChatHistoryLoaded.remove(key);
    }
  }

  Future<void> sendMatchChatMessage(Pick p, String text) async {
    if (text.trim().isEmpty) return;
    final key = _matchKey(p);
    final thread = matchChats.putIfAbsent(key, () => []);
    thread.add(ChatMessage(role: ChatRole.user, text: text.trim()));
    matchChatLoading.add(key);
    notifyListeners();

    try {
      final reply = await ChatService.instance.sendMessage(p.id, text.trim());
      thread.add(ChatMessage(
        role: ChatRole.ai,
        text: reply.text,
        outcomes: reply.outcomes,
        suggestions: reply.suggestions,
      ));
    } on ChatLimitReachedException {
      thread.add(const ChatMessage(
        role: ChatRole.ai,
        text: 'Llegaste al límite diario de mensajes del plan Free. Con Premium el chat es ilimitado.',
      ));
    } catch (_) {
      thread.add(const ChatMessage(
        role: ChatRole.ai,
        text: 'No pude conectar con el análisis ahora mismo. Intenta de nuevo en un momento.',
      ));
    } finally {
      matchChatLoading.remove(key);
      notifyListeners();
    }
  }

  String _matchKey(Pick p) => '${p.teamA}-${p.teamB}-${p.time}';

  List<Pick> get filteredPicks {
    final today = selectedDate;
    final picks = allPicks.where((p) => (filter == 'all' || p.sport == filter) && p.matchDate == today).toList();
    picks.sort((a, b) {
      if (favoriteLeagueIds.isNotEmpty) {
        final aFav = favoriteLeagueIds.contains(a.leagueId) ? 0 : 1;
        final bFav = favoriteLeagueIds.contains(b.leagueId) ? 0 : 1;
        if (aFav != bFav) return aFav.compareTo(bFav);
      }
      final aLocked = isLocked(a) ? 1 : 0;
      final bLocked = isLocked(b) ? 1 : 0;
      return aLocked.compareTo(bLocked);
    });
    return picks;
  }

  bool isLocked(Pick p) => !kDevUnlockAll && p.premium && plan == 'free';

  Pick get selectedPick =>
      allPicks.firstWhere((p) => p.id == selectedId, orElse: () => allPicks.first);
}
