import 'package:flutter/material.dart';

final appLocaleNotifier = ValueNotifier<Locale>(const Locale('en'));

void toggleAppLocale() {
  final current = appLocaleNotifier.value;
  appLocaleNotifier.value =
      current.languageCode == 'en' ? const Locale('es') : const Locale('en');
}

extension AppStringsLookup on BuildContext {
  AppStrings get strings => AppStrings(AppLocaleScope.localeOf(this));
}

class AppLocaleScope extends InheritedWidget {
  const AppLocaleScope({required this.locale, required super.child, super.key});

  final Locale locale;

  static Locale localeOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppLocaleScope>()
            ?.locale ??
        Localizations.localeOf(context);
  }

  @override
  bool updateShouldNotify(AppLocaleScope oldWidget) {
    return oldWidget.locale != locale;
  }
}

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  bool get isSpanish => locale.languageCode == 'es';

  String get appName => "Ricky's World Cup Bracket 2026";
  String get languageButton => isSpanish ? 'English' : 'Español';
  String get admin => isSpanish ? 'Admin' : 'Admin';
  String get home => isSpanish ? 'Inicio' : 'Home';
  String get bracket => isSpanish ? 'Bracket' : 'Bracket';
  String get standings => isSpanish ? 'Tabla' : 'Standings';
  String get leaders => isSpanish ? 'Líderes' : 'Leaders';
  String get profile => isSpanish ? 'Perfil' : 'Profile';
  String get chat => isSpanish ? 'Chat' : 'Chat';

  String get buildFullBracket =>
      isSpanish
          ? 'Crea tu bracket completo del Mundial 2026'
          : 'Build your full 2026 World Cup bracket';
  String get homeIntro =>
      isSpanish
          ? 'Crea un usuario gratis, elige cada país que avanza y compite en la tabla global.'
          : 'Create a free username, pick every country that advances, and compete on the global leaderboard.';
  String get startFree => isSpanish ? 'Empieza gratis' : 'Start free';
  String get createUsernameBeforeBracket =>
      isSpanish
          ? 'Crea un perfil de usuario antes de armar tu bracket.'
          : 'Create a username profile before building your bracket.';
  String get createUsername => isSpanish ? 'Crear usuario' : 'Create username';
  String welcome(String username) =>
      isSpanish ? 'Bienvenido, $username' : 'Welcome, $username';
  String get profilePublicFree =>
      isSpanish
          ? 'Tu perfil es público y gratis.'
          : 'Your profile is public and free to use.';
  String get viewProfile => isSpanish ? 'Ver perfil' : 'View profile';
  String get bracketLocked =>
      isSpanish ? 'Bracket bloqueado' : 'Bracket locked';
  String get bracketLockDeadline =>
      isSpanish ? 'Fecha límite del bracket' : 'Bracket lock deadline';
  String picksLockAt(String date) =>
      isSpanish
          ? 'Las selecciones se bloquean el $date.'
          : 'Picks lock at $date.';
  String get openBracket => isSpanish ? 'Abrir bracket' : 'Open bracket';
  String bracketStatus(String status) =>
      isSpanish ? 'Estado del bracket: $status' : 'Bracket status: $status';
  String savedPicks(int groups, int knockouts) =>
      isSpanish
          ? '$groups/12 grupos y $knockouts/31 selecciones eliminatorias guardadas.'
          : '$groups/12 groups and $knockouts/31 knockout picks saved.';
  String get continuePicks =>
      isSpanish ? 'Continuar selecciones' : 'Continue picks';
  String couldNotLoad(String item, Object error) =>
      isSpanish
          ? 'No se pudo cargar $item: $error'
          : 'Could not load $item: $error';

  String get createFreeProfile =>
      isSpanish
          ? 'Crea tu perfil gratis de bracket'
          : 'Create your free bracket profile';
  String get onboardingIntro =>
      isSpanish
          ? 'Elige un usuario único para guardar tu bracket. Más adelante puedes vincular una cuenta para recuperar tu perfil en iPhone, Android, navegador, Windows y macOS.'
          : 'Pick a unique username to save your bracket. Account linking can be added later for recovery across iPhone, Android, browser, Windows, and macOS.';
  String get username => isSpanish ? 'Usuario' : 'Username';
  String get usernameHelp =>
      isSpanish
          ? '3-20 letras, números o guiones bajos'
          : '3-20 letters, numbers, or underscores';
  String get createProfile => isSpanish ? 'Crear perfil' : 'Create profile';

  String get yourGlobalBracket =>
      isSpanish ? 'Tu bracket global' : 'Your global bracket';
  String get bracketReadOnly =>
      isSpanish
          ? 'El concurso global está bloqueado. Las selecciones son de solo lectura.'
          : 'The global contest is locked. Picks are read-only.';
  String get autosaveEnabled =>
      isSpanish
          ? 'El autoguardado está activado. Completa cada grupo y cada ronda antes del primer partido.'
          : 'Autosave is enabled. Complete every group and knockout slot before the first kickoff.';
  String get groupStage => isSpanish ? 'Fase de grupos' : 'Group stage';
  String get groupInstructions =>
      isSpanish
          ? 'Elige quién termina primero, segundo y tercero en cada grupo.'
          : 'Pick who finishes first, second, and third in each group.';
  String group(String groupId) =>
      isSpanish ? 'Grupo $groupId' : 'Group $groupId';
  String get firstPlace => isSpanish ? '1.º' : '1st';
  String get secondPlace => isSpanish ? '2.º' : '2nd';
  String get thirdPlace => isSpanish ? '3.º' : '3rd';
  String get bestThirdPlaceTeams =>
      isSpanish ? 'Mejores terceros lugares' : 'Best third-place teams';
  String bestThirdInstructions(int count) =>
      isSpanish
          ? 'Elige exactamente 8 equipos de tercer lugar que avanzan. Seleccionados: $count de 8.'
          : 'Pick exactly 8 third-place teams to advance. Selected: $count of 8.';
  String groupThirdPick(String groupId, String country) =>
      isSpanish ? 'Grupo $groupId: $country' : 'Group $groupId: $country';
  String groupThirdNotPicked(String groupId) =>
      isSpanish
          ? 'Grupo $groupId: elige tercer lugar primero'
          : 'Group $groupId: pick 3rd place first';
  String get knockoutBracket =>
      isSpanish ? 'Bracket eliminatorio' : 'Knockout bracket';
  String get knockoutInstructions =>
      isSpanish
          ? 'Elige cada ganador desde la ronda de 32 hasta la final.'
          : 'Pick every winner from the round of 32 to the final.';
  String get winner => isSpanish ? 'Ganador' : 'Winner';
  String get pickDidNotMakeMatch =>
      isSpanish
          ? 'Esta selección no llegó a este partido.'
          : 'This pick did not make this match.';
  String get completeReady =>
      isSpanish
          ? 'Tu bracket está completo y listo para enviar.'
          : 'Your bracket is complete and ready to submit.';
  String get completeBeforeSubmit =>
      isSpanish
          ? 'Completa todas las selecciones antes de enviar.'
          : 'Complete all picks before submitting.';
  String get submitBracket => isSpanish ? 'Enviar bracket' : 'Submit bracket';
  String get roundOf32 => isSpanish ? 'Ronda de 32' : 'Round of 32';
  String get roundOf16 => isSpanish ? 'Ronda de 16' : 'Round of 16';
  String get quarterfinals => isSpanish ? 'Cuartos de final' : 'Quarterfinals';
  String get semifinals => isSpanish ? 'Semifinales' : 'Semifinals';
  String get finalRound => isSpanish ? 'Final' : 'Final';

  String get globalLeaderboard =>
      isSpanish ? 'Tabla global' : 'Global leaderboard';
  String get scoringExplainer =>
      isSpanish
          ? 'Puntuación simple: cada selección correcta vale un punto. El marcador de la final desempata.'
          : 'Flat scoring: every correct pick is worth one point. Final score prediction breaks ties.';
  String get rank => isSpanish ? 'Lugar' : 'Rank';
  String get score => isSpanish ? 'Puntos' : 'Score';
  String get tie => isSpanish ? 'Desempate' : 'Tie';

  String get teamsFlagsFixtures =>
      isSpanish ? 'Equipos, banderas y partidos' : 'Teams, flags, and fixtures';
  String get countryDataExplainer =>
      isSpanish
          ? 'Los países usan API-Football como fuente principal con banderas de respaldo incluidas.'
          : 'Country data uses API-Football as the canonical source with bundled fallback flag assets.';
  String get fixtureSyncPreview =>
      isSpanish
          ? 'Vista previa de partidos sincronizados'
          : 'Fixture sync preview';
  String get vs => isSpanish ? 'contra' : 'vs';

  String get publicProfile => isSpanish ? 'Perfil público' : 'Public profile';
  String get noRecoveryLinked =>
      isSpanish
          ? 'Sin cuenta de recuperación vinculada'
          : 'No recovery account linked';
  String linked(String providers) =>
      isSpanish ? 'Vinculado: $providers' : 'Linked: $providers';
  String get accountRecovery =>
      isSpanish ? 'Recuperación de cuenta' : 'Account recovery';
  String get accountRecoveryBody =>
      isSpanish
          ? 'La vinculación opcional ayuda a recuperar brackets en varios dispositivos sin dejar de ser gratis.'
          : 'Optional linking helps recover brackets across devices while keeping signup free.';
  String linkProvider(String provider) =>
      isSpanish ? 'Vincular $provider' : 'Link $provider';
  String get lockNotifications =>
      isSpanish
          ? 'Notificaciones de bloqueo y tabla'
          : 'Lock and leaderboard notifications';
  String get notificationBody =>
      isSpanish
          ? 'Recordatorios opcionales y actualizaciones de la tabla.'
          : 'Optional reminders and leaderboard updates.';
  String championPick(String champion) =>
      isSpanish ? 'Campeón elegido: $champion' : 'Champion pick: $champion';
  String get view => isSpanish ? 'Ver' : 'View';
  String get reportProfile => isSpanish ? 'Reportar perfil' : 'Report profile';
  String get reason => isSpanish ? 'Razón' : 'Reason';
  String get submitReport => isSpanish ? 'Enviar reporte' : 'Submit report';
  String get reportSubmitted =>
      isSpanish ? 'Reporte enviado' : 'Report submitted';

  String get adminConsole =>
      isSpanish ? 'Consola de administrador' : 'Admin console';
  String get adminAccessDenied =>
      isSpanish ? 'Acceso de administrador denegado' : 'Admin access denied';
  String get adminAccessDeniedBody =>
      isSpanish
          ? 'Inicia sesión con el correo de administrador configurado para ver esta pantalla.'
          : 'Sign in with the configured admin email to view this screen.';
  String get adminLogin =>
      isSpanish ? 'Iniciar sesión de admin' : 'Admin sign in';
  String get adminEmail => isSpanish ? 'Correo de admin' : 'Admin email';
  String get password => isSpanish ? 'Contraseña' : 'Password';
  String get signIn => isSpanish ? 'Iniciar sesión' : 'Sign in';
  String get adminEmailLocked =>
      isSpanish
          ? 'Solo rgw1985@hotmail.com puede acceder como admin.'
          : 'Only rgw1985@hotmail.com can access admin.';
  String get passwordRequired =>
      isSpanish ? 'Escribe la contraseña.' : 'Enter the password.';
  String get adminEmailNotConfigured =>
      isSpanish
          ? 'ADMIN_EMAIL no está configurado para esta compilación.'
          : 'ADMIN_EMAIL is not configured for this build.';
  String get adminExplainer =>
      isSpanish
          ? 'El acceso de producción se protege con Firebase custom claims y Cloud Functions. Estas pantallas definen la administración dentro de la app Flutter compartida.'
          : 'Production access is enforced with Firebase custom claims and Cloud Functions. These screens define the admin surface in the shared Flutter app.';
  String get apiFootballSync =>
      isSpanish ? 'Sincronización API-Football' : 'API-Football sync';
  String get apiFootballSyncBody =>
      isSpanish
          ? 'Revisa el estado, actualiza partidos/tablas e inspecciona errores del proveedor.'
          : 'Review sync status, trigger fixture/standings refresh, and inspect provider errors.';
  String get syncNow => isSpanish ? 'Sincronizar' : 'Sync now';
  String get teamsAndFlags =>
      isSpanish ? 'Equipos y banderas' : 'Teams and flags';
  String get teamsAndFlagsBody =>
      isSpanish
          ? 'Corrige nombres, abreviaturas, IDs de API, URLs de bandera y respaldos.'
          : 'Override country names, abbreviations, API IDs, flag URLs, and fallback asset keys.';
  String get reviewTeams => isSpanish ? 'Revisar equipos' : 'Review teams';
  String get fixturesAndResults =>
      isSpanish ? 'Partidos y resultados' : 'Fixtures and results';
  String get fixturesAndResultsBody =>
      isSpanish
          ? 'Corrige horarios, estados, marcadores, ganadores y bloqueo del bracket.'
          : 'Correct kickoff times, statuses, scores, winners, and bracket lock timing.';
  String get reviewFixtures =>
      isSpanish ? 'Revisar partidos' : 'Review fixtures';
  String get moderation => isSpanish ? 'Moderación' : 'Moderation';
  String get moderationBody =>
      isSpanish
          ? 'Revisa reportes, oculta perfiles/brackets abusivos y renombra usuarios.'
          : 'Review reports, hide abusive profiles/brackets, and rename users when needed.';
  String get reviewReports => isSpanish ? 'Revisar reportes' : 'Review reports';
  String loadedCountries(int count) =>
      isSpanish ? 'Países cargados: $count' : 'Loaded countries: $count';
  String loadedFixtures(int count) =>
      isSpanish ? 'Partidos cargados: $count' : 'Loaded fixtures: $count';

  String get globalChat => isSpanish ? 'Chat global' : 'Global chat';
  String get chatExplainer =>
      isSpanish
          ? 'Chat de beta privada para todos los usuarios. Los mensajes se actualizan en tiempo real y se conservan por 30 días.'
          : 'Private beta chat for all users. Messages update in realtime and are kept for 30 days.';
  String get createProfileToChat =>
      isSpanish
          ? 'Crea un usuario para enviar mensajes.'
          : 'Create a username profile to send messages.';
  String get message => isSpanish ? 'Mensaje' : 'Message';
  String get send => isSpanish ? 'Enviar' : 'Send';
  String get edit => isSpanish ? 'Editar' : 'Edit';
  String get delete => isSpanish ? 'Eliminar' : 'Delete';
  String get save => isSpanish ? 'Guardar' : 'Save';
  String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  String get edited => isSpanish ? 'editado' : 'edited';
  String get deletedMessage =>
      isSpanish ? 'Mensaje eliminado' : 'Message deleted';
  String get addReaction => isSpanish ? 'Agregar reacción' : 'Add reaction';
  String get noChatMessages =>
      isSpanish ? 'Todavía no hay mensajes.' : 'No messages yet.';
  String get messageTooLong =>
      isSpanish
          ? 'El mensaje debe tener 1,000 caracteres o menos.'
          : 'Message must be 1,000 characters or fewer.';
  String get messageRequired =>
      isSpanish ? 'Escribe un mensaje primero.' : 'Write a message first.';
}
