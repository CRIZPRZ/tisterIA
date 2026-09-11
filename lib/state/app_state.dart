import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/mock_data.dart';
import '../models/baseball_game.dart';
import '../models/chat.dart';
import '../models/pick.dart';
import '../services/accuracy_service.dart';
import '../services/ads_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/favorite_teams_service.dart';
import '../services/follows_service.dart';
import '../services/iap_service.dart';
import '../services/notifications_service.dart';
import '../services/picks_service.dart';
import '../services/push_service.dart';
import '../services/team_service.dart';
import '../services/usage_service.dart';

/// Dev-only: cuando es true, ningún pick se bloquea sin importar el plan.
/// Ponlo en false para probar el flujo real de paywall.
const bool kDevUnlockAll = false;

/// Dev-only: simula que la carga de picks falla por red, para previsualizar
/// el estado de error. Déjalo en false en desarrollo normal.
const bool kSimulateNetworkError = false;

class LiveClockAnchor {
  final int minute;
  final int? extra;
  final DateTime capturedAt;
  const LiveClockAnchor({required this.minute, required this.extra, required this.capturedAt});
}

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
  termsGate,
  termsDoc,
  privacyDoc,
  teamHistory,
  teamPicker,
  shotMapDemo,
  kboResults,
  kboDetail,
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
    case AppScreen.termsDoc:
    case AppScreen.privacyDoc:
      return AppScreen.termsGate;
    case AppScreen.teamHistory:
      return AppScreen.home;
    case AppScreen.teamPicker:
      return AppScreen.leaguePreferences;
    case AppScreen.shotMapDemo:
      return AppScreen.profile;
    case AppScreen.kboResults:
      return AppScreen.profile;
    case AppScreen.kboDetail:
      return AppScreen.kboResults;
    case AppScreen.onboarding:
    case AppScreen.home:
    case AppScreen.profile:
    case AppScreen.onboardingPreferences:
    case AppScreen.leagues:
    case AppScreen.chatPicker:
    case AppScreen.termsGate:
      return null;
  }
}

class AppState extends ChangeNotifier {
  AppScreen screen = AppScreen.onboarding;
  String? selectedId;
  String filter = 'all';

  // Tab que debe abrir DetailScreen al entrar (ej. "Alineación" al tocar
  // una notificación de alineación confirmada) — DetailScreen la consume
  // y la limpia, para no re-disparar en cada rebuild.
  int? pendingDetailTabIndex;

  static const _notifTabIndex = {'alineacion': 1};

  Future<void> openFromNotification(String pickId, {String? type}) async {
    // Si la app arrancó en frío desde la notificación, allPicks puede
    // seguir vacío en este momento — sin esto, selectedPick cae en
    // allPicks.first (o revienta si allPicks sigue vacío).
    if (!allPicks.any((p) => p.id == pickId)) {
      await loadPicks();
    }
    if (!allPicks.any((p) => p.id == pickId)) return; // fixture ya no disponible
    await openDetail(pickId, tabIndex: _notifTabIndex[type]);
  }

  String? homeLeagueFilter;

  void setHomeLeagueFilter(String? league) {
    homeLeagueFilter = league;
    notifyListeners();
  }

  bool showLiveOnly = false;

  void toggleLiveOnly() {
    showLiveOnly = !showLiveOnly;
    notifyListeners();
  }

  // null = sin filtro de fecha (se ve todo, agrupado por día). Un valor
  // "YYYY-MM-DD" filtra Home a ese día únicamente — reemplaza al viejo
  // showTodayOnly/toggleTodayOnly booleano, ahora hay un chip por cada
  // fecha con partidos (Hoy, Mañana, y así), no solo "Hoy".
  String? homeDateFilter;

  void setHomeDateFilter(String? date) {
    homeDateFilter = homeDateFilter == date ? null : date;
    notifyListeners();
  }

  BaseballGame? kboSelectedGame;

  void openKboDetail(BaseballGame game) {
    kboSelectedGame = game;
    screen = AppScreen.kboDetail;
    notifyListeners();
  }

  int? teamHistoryId;
  String teamHistoryName = '';
  List<Pick> teamHistoryMatches = [];
  bool teamHistoryLoading = false;
  TeamStats? teamHistoryStats;
  bool teamHistoryStatsLoading = false;

  void openTeamHistory(int teamId, String teamName, [int? leagueId]) {
    teamHistoryId = teamId;
    teamHistoryName = teamName;
    teamHistoryMatches = [];
    teamHistoryLoading = true;
    teamHistoryStats = null;
    teamHistoryStatsLoading = leagueId != null;
    screen = AppScreen.teamHistory;
    notifyListeners();
    TeamService.instance.fetchMatches(teamId).then((matches) {
      if (teamHistoryId != teamId) return; // el usuario ya navegó a otro equipo
      teamHistoryMatches = matches;
      teamHistoryLoading = false;
      notifyListeners();
    }).catchError((_) {
      if (teamHistoryId != teamId) return;
      teamHistoryLoading = false;
      notifyListeners();
    });
    if (leagueId != null) {
      TeamService.instance.fetchStats(teamId, leagueId).then((stats) {
        if (teamHistoryId != teamId) return;
        teamHistoryStats = stats;
        teamHistoryStatsLoading = false;
        notifyListeners();
      }).catchError((_) {
        if (teamHistoryId != teamId) return;
        // silencioso — no todos los equipos tienen stats todavía (temporada
        // recién empezada), no debe verse como un error de red
        teamHistoryStatsLoading = false;
        notifyListeners();
      });
    }
  }

  int? teamPickerLeagueId;
  String teamPickerLeagueName = '';
  List<TeamOption> teamPickerOptions = [];
  bool teamPickerLoading = false;
  bool teamPickerError = false;

  void openTeamPicker(int leagueId, String leagueName) {
    teamPickerLeagueId = leagueId;
    teamPickerLeagueName = leagueName;
    teamPickerOptions = [];
    teamPickerLoading = true;
    teamPickerError = false;
    screen = AppScreen.teamPicker;
    notifyListeners();
    TeamService.instance.fetchByLeague(leagueId).then((teams) {
      if (teamPickerLeagueId != leagueId) return; // ya navegó a otra liga
      teamPickerOptions = teams;
      teamPickerLoading = false;
      notifyListeners();
    }).catchError((_) {
      if (teamPickerLeagueId != leagueId) return;
      teamPickerLoading = false;
      teamPickerError = true;
      notifyListeners();
    });
  }

  Set<int> followedFixtureIds = {};
  final Set<int> _followInFlight = {};

  bool isFollowing(Pick pick) => pick.fixtureId != null && followedFixtureIds.contains(pick.fixtureId);

  Future<void> toggleFollow(Pick pick) async {
    final fixtureId = pick.fixtureId;
    if (fixtureId == null) return;
    // evita doble-toggle (doble tap, o dos cards de la misma fixture) antes
    // de que responda el request anterior — si no, el segundo tap lee el set
    // ya optimista del primero y lo revierte antes de que ninguno confirme.
    if (_followInFlight.contains(fixtureId)) return;
    _followInFlight.add(fixtureId);
    final wasFollowing = followedFixtureIds.contains(fixtureId);
    final desired = !wasFollowing;
    // optimista: refleja el cambio ya, revierte si falla la red
    if (wasFollowing) {
      followedFixtureIds.remove(fixtureId);
    } else {
      followedFixtureIds.add(fixtureId);
    }
    notifyListeners();
    try {
      final following = await FollowsService.instance.setFollowing(pick.id, desired);
      if (following != desired) {
        // el backend dijo algo distinto a lo que asumimos — nos alineamos
        if (following) {
          followedFixtureIds.add(fixtureId);
        } else {
          followedFixtureIds.remove(fixtureId);
        }
        notifyListeners();
      }
    } catch (_) {
      // revierte el cambio optimista si falló la red
      if (wasFollowing) {
        followedFixtureIds.add(fixtureId);
      } else {
        followedFixtureIds.remove(fixtureId);
      }
      notifyListeners();
    } finally {
      _followInFlight.remove(fixtureId);
    }
  }

  String plan = 'free';
  bool forgotSent = false;

  List<Pick> allPicks = [];

  // Reloj en vivo: vive aquí (no en el widget) para no reiniciarse cada vez
  // que sales y vuelves a entrar a la pantalla del partido. Solo se
  // actualiza el "ancla" cuando la API manda un minuto/extra REALMENTE
  // distinto al que ya teníamos — mientras tanto, el minuto:segundo que se
  // muestra se calcula sumando el tiempo real transcurrido desde esa ancla,
  // así el conteo es continuo y solo "salta" cuando de verdad hay dato
  // nuevo del servidor.
  final Map<String, LiveClockAnchor> _liveAnchors = {};

  void _refreshLiveAnchors() {
    final liveIds = <String>{};
    for (final p in allPicks) {
      if (!p.isLive || p.liveMinute == null) continue;
      liveIds.add(p.id);
      final existing = _liveAnchors[p.id];
      if (existing == null || existing.minute != p.liveMinute || existing.extra != p.liveExtra) {
        _liveAnchors[p.id] = LiveClockAnchor(minute: p.liveMinute!, extra: p.liveExtra, capturedAt: DateTime.now());
      }
    }
    _liveAnchors.removeWhere((id, _) => !liveIds.contains(id));
  }

  LiveClockAnchor? liveAnchorFor(String pickId) => _liveAnchors[pickId];

  Future<bool> loadPicks() async {
    try {
      allPicks = await PicksService.instance.fetchPicks();
      _refreshLiveAnchors();
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

  Future<void> loadAccuracy({String? league, String? date}) async {
    accuracyLoading = true;
    accuracyError = false;
    notifyListeners();
    try {
      accuracy = await AccuracyService.instance.fetchAccuracy(league: league, date: date);
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

  static const _onboardingGateKey = 'tipster_onboarding_gate_done';
  final FlutterSecureStorage _onboardingStorage = const FlutterSecureStorage();

  bool ageConfirmed = false;
  bool marketingOptIn = false;

  void setAgeConfirmed(bool value) {
    ageConfirmed = value;
    notifyListeners();
  }

  void setMarketingOptIn(bool value) {
    marketingOptIn = value;
    notifyListeners();
  }

  /// Se llama al aceptar términos y privacidad — no se vuelve a mostrar
  /// el paso de idioma/términos en aperturas futuras de la app.
  Future<void> completeOnboardingGate() async {
    await _onboardingStorage.write(key: _onboardingGateKey, value: 'true');
    screen = AppScreen.onboarding;
    notifyListeners();
  }

  Future<void> _bootstrap() async {
    final user = await AuthService.instance.tryRestoreSession();
    currentUser = user;
    isBootstrapping = false;
    if (user != null) {
      screen = AppScreen.home;
      _afterAuth();
    } else {
      final gateDone = await _onboardingStorage.read(key: _onboardingGateKey);
      if (gateDone != 'true') {
        screen = AppScreen.termsGate;
      }
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
    PushService.instance.registerForPush(this);

    // Estas 5 no dependen entre sí — antes se pedían una por una (varios
    // round trips seguidos al servidor, ahí se iban los ~5s al abrir la
    // app). En paralelo, el tiempo total es el de la más lenta, no la suma.
    await Future.wait([
      _loadFavoriteTeams(),
      () async {
        try {
          final prefs = await NotificationsService.instance.fetchPrefs();
          notifPrefs
            ..clear()
            ..addAll(prefs);
          notifyListeners();
        } catch (_) {
          // se queda con los defaults locales si el backend no responde
        }
      }(),
      () async {
        try {
          followedFixtureIds = await FollowsService.instance.fetchFollowed();
          notifyListeners();
        } catch (_) {
          // sin conexión — se queda vacío, no bloquea el arranque
        }
      }(),
      () async {
        // Re-verifica contra Google Play por si la suscripción se canceló o
        // venció desde la última vez que se abrió la app (sin webhooks todavía).
        try {
          final status = await IapService.instance.fetchStatus();
          plan = status.plan;
          notifyListeners();
        } catch (_) {
          // sin conexión con Play o sin suscripción previa — se queda con lo local
        }
      }(),
      loadUsage(),
    ]);
  }

  // Cuota diaria (plan Free) — se usa en Home para mostrar como "gratis
  // abierto" solo los partidos que de verdad se pueden abrir hoy, en vez
  // de poner el badge FREE en todos y que el candado sorprenda hasta que
  // tocas.
  UsageInfo? usage;

  Future<void> loadUsage() async {
    try {
      usage = await UsageService.instance.fetchToday();
      notifyListeners();
    } catch (_) {
      // sin conexión — Home cae de vuelta a "todo FREE visible" (peor UX,
      // no bloqueo falso)
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

  // Equipos favoritos GLOBALES (no por liga) — un club puede jugar varios
  // torneos a la vez (ej. Club America en Liga MX y Leagues Cup), así que
  // el favorito aplica a todos. Vive en el server (alimenta el auto-follow
  // de notificaciones ahí), no solo local — se sincroniza al login.
  final Set<int> favoriteTeamIds = {};
  final Map<int, String> favoriteTeamNames = {}; // solo para mostrar nombre sin re-pedir el roster
  final Set<int> _favoriteTeamInFlight = {};

  Future<void> _loadFavoriteTeams() async {
    try {
      final ids = await FavoriteTeamsService.instance.fetchFavorites();
      favoriteTeamIds
        ..clear()
        ..addAll(ids);
      notifyListeners();
    } catch (_) {
      // sin conexión al abrir — se queda vacío, no bloquea el arranque
    }
  }

  bool isFavoriteTeam(int teamId) => favoriteTeamIds.contains(teamId);

  Future<void> setFavoriteTeam(int teamId, bool favorite, {String? teamName}) async {
    if (_favoriteTeamInFlight.contains(teamId)) return;
    _favoriteTeamInFlight.add(teamId);
    final wasFavorite = favoriteTeamIds.contains(teamId);
    if (favorite) {
      favoriteTeamIds.add(teamId);
      if (teamName != null) favoriteTeamNames[teamId] = teamName;
    } else {
      favoriteTeamIds.remove(teamId);
    }
    notifyListeners();
    try {
      final confirmed = await FavoriteTeamsService.instance.setFavorite(teamId, favorite);
      if (confirmed != favorite) {
        if (confirmed) {
          favoriteTeamIds.add(teamId);
        } else {
          favoriteTeamIds.remove(teamId);
        }
        notifyListeners();
      }
    } catch (_) {
      if (wasFavorite) {
        favoriteTeamIds.add(teamId);
      } else {
        favoriteTeamIds.remove(teamId);
      }
      notifyListeners();
    } finally {
      _favoriteTeamInFlight.remove(teamId);
    }
  }

  void go(AppScreen s) {
    screen = s;
    notifyListeners();
  }

  String? pendingPickId;

  /// Cuota diaria de picks del plan Free: si ya se acabó, manda a Paywall
  /// en vez de abrir el partido. Premium/Pro no tienen límite.
  Future<void> openDetail(String id, {int? tabIndex}) async {
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
        loadUsage(); // refresca para que Home ya marque este fixture como visto
      } catch (_) {
        // si falla la red no bloqueamos al usuario con un candado falso
      }
    }
    selectedId = id;
    pendingDetailTabIndex = tabIndex;
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

  /// true si el pick es de un partido donde juega un equipo favorito
  /// (global — cualquier liga/torneo, más específico que "liga favorita").
  bool isFavoriteTeamPick(Pick p) {
    if (p.teamAId != null && favoriteTeamIds.contains(p.teamAId)) return true;
    if (p.teamBId != null && favoriteTeamIds.contains(p.teamBId)) return true;
    return false;
  }

  List<Pick> get filteredPicks {
    final picks = allPicks.where((p) => filter == 'all' || p.sport == filter).toList();
    picks.sort((a, b) {
      if (favoriteTeamIds.isNotEmpty) {
        final aTeam = isFavoriteTeamPick(a) ? 0 : 1;
        final bTeam = isFavoriteTeamPick(b) ? 0 : 1;
        if (aTeam != bTeam) return aTeam.compareTo(bTeam);
      }
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

  /// Pick gratis (mercado 0) que hoy ya no se puede abrir porque se acabó
  /// la cuota diaria — a diferencia de [isLocked], que es por mercado
  /// premium. Ya visto hoy no cuenta (se puede reabrir sin gastar cuota).
  bool isPickQuotaLocked(Pick p) {
    if (kDevUnlockAll || p.premium || plan != 'free') return false;
    final info = usage;
    if (info == null || info.picksLimit == null) return false;
    if (p.fixtureId != null && info.viewedFixtureIds.contains(p.fixtureId)) return false;
    return info.picksViewedToday >= info.picksLimit!;
  }

  Pick get selectedPick =>
      allPicks.firstWhere((p) => p.id == selectedId, orElse: () => allPicks.first);
}
