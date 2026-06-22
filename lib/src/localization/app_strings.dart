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
  String get standingsLegendTitle =>
      isSpanish ? 'Significado de las columnas' : 'What the columns mean';
  String get standingsLegendForm =>
      isSpanish ? 'Forma reciente (últimos 5)' : 'Recent form (last 5 games)';
  String showGroupGames(int count) =>
      isSpanish ? 'Ver $count partidos' : 'Show $count games';
  String get hideGroupGames =>
      isSpanish ? 'Ocultar partidos' : 'Hide games';
  List<StandingsLegendEntry> get standingsLegendEntries =>
      isSpanish
          ? const [
            StandingsLegendEntry('P', 'Jugados'),
            StandingsLegendEntry('W', 'Ganados'),
            StandingsLegendEntry('D', 'Empates'),
            StandingsLegendEntry('L', 'Perdidos'),
            StandingsLegendEntry('GF', 'Goles a favor'),
            StandingsLegendEntry('GA', 'Goles en contra'),
            StandingsLegendEntry('GD', 'Diferencia de goles'),
            StandingsLegendEntry('Pts', 'Puntos (3 por victoria, 1 por empate)'),
          ]
          : const [
            StandingsLegendEntry('P', 'Played'),
            StandingsLegendEntry('W', 'Won'),
            StandingsLegendEntry('D', 'Drawn'),
            StandingsLegendEntry('L', 'Lost'),
            StandingsLegendEntry('GF', 'Goals for'),
            StandingsLegendEntry('GA', 'Goals against'),
            StandingsLegendEntry('GD', 'Goal difference'),
            StandingsLegendEntry('Pts', 'Points (3 for a win, 1 for a draw)'),
          ];
  String get amysCalendar => "Amy's Calendar";
  String get leaders => isSpanish ? 'Líderes' : 'Leaders';
  String get players => isSpanish ? 'Jugadores' : 'Players';
  String get profile => isSpanish ? 'Perfil' : 'Profile';
  String get chat => isSpanish ? 'Chat' : 'Chat';
  String get navStandingsShort => isSpanish ? 'Tabla' : 'Table';
  String get navPlayersShort => isSpanish ? 'Lista' : 'Players';

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
          ? 'Inicia sesión o crea una cuenta antes de armar tu bracket.'
          : 'Sign in or create an account before building your bracket.';
  String get createUsername => isSpanish ? 'Iniciar sesión' : 'Sign in';
  String get signedOutTitle =>
      isSpanish ? 'Sesión cerrada' : 'You are signed out';
  String get signedOutBody =>
      isSpanish
          ? 'Inicia sesión o crea una cuenta para crear tu bracket, ver jugadores y usar el chat.'
          : 'Sign in or create an account to build your bracket, view players, and use chat.';
  String get signInOrCreateAccount =>
      isSpanish ? 'Iniciar sesión o crear cuenta' : 'Sign in or create account';
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
  String get accountAccess =>
      isSpanish ? 'Acceso a tu bracket' : 'Bracket account access';
  String get onboardingIntro =>
      isSpanish
          ? 'Inicia sesión o crea una cuenta con usuario, contraseña y correo o teléfono. Tu usuario es público; tu contacto queda privado.'
          : 'Sign in or create an account with a username, password, and email or phone. Your username is public; your contact info stays private.';
  String get alreadySignedIn =>
      isSpanish
          ? 'Ya iniciaste sesión en esta cuenta.'
          : 'You are already signed in to this account.';
  String get username => isSpanish ? 'Usuario' : 'Username';
  String get usernameOrEmail =>
      isSpanish ? 'Usuario o correo' : 'Username or email';
  String get usernameOrEmailRequired =>
      isSpanish
          ? 'Escribe tu usuario o correo.'
          : 'Enter your username or email.';
  String get usernameHelp =>
      isSpanish
          ? '3-20 letras, números o guiones bajos'
          : '3-20 letters, numbers, or underscores';
  String get createProfile => isSpanish ? 'Crear perfil' : 'Create profile';
  String get createAccount => isSpanish ? 'Crear cuenta' : 'Create account';
  String get email => isSpanish ? 'Correo' : 'Email';
  String get phone => isSpanish ? 'Teléfono' : 'Phone';
  String get emailOrPhoneHelp =>
      isSpanish
          ? 'Necesitas correo o teléfono. El correo permite restablecer contraseña.'
          : 'Email or phone is required. Email enables password reset.';
  String get emailOrPhoneRequired =>
      isSpanish
          ? 'Escribe un correo o teléfono.'
          : 'Enter an email or phone number.';
  String get passwordHelp =>
      isSpanish ? 'Mínimo 6 caracteres' : 'Minimum 6 characters';
  String get passwordMinLength =>
      isSpanish
          ? 'La contraseña debe tener al menos 6 caracteres.'
          : 'Password must be at least 6 characters.';
  String get forgotPassword =>
      isSpanish ? 'Olvidé mi contraseña' : 'Forgot password?';
  String get sendingPasswordReset => isSpanish ? 'Enviando...' : 'Sending...';
  String get passwordResetSent =>
      isSpanish
          ? 'Si la cuenta tiene correo, se envió un enlace para restablecer la contraseña.'
          : 'If the account has an email, a password reset link was sent.';

  String get yourGlobalBracket =>
      isSpanish ? 'Tu bracket global' : 'Your global bracket';
  String get bracketReadOnly =>
      isSpanish
          ? 'El concurso global está bloqueado. Las selecciones son de solo lectura.'
          : 'The global contest is locked. Picks are read-only.';
  String get submissionsClosedByAdmin =>
      isSpanish
          ? 'El administrador cerró las inscripciones. Las selecciones son de solo lectura.'
          : 'The admin closed submissions. Picks are read-only.';
  String adminSubmissionsOpen(String lockAtLocal) =>
      isSpanish
          ? 'Inscripciones ABIERTAS hasta $lockAtLocal'
          : 'Submissions OPEN until $lockAtLocal';
  String get adminSubmissionsClosedByAdmin =>
      isSpanish
          ? 'Inscripciones CERRADAS — desactivadas por el admin'
          : 'Submissions CLOSED — turned off by admin';
  String adminSubmissionsClosedByLock(String lockAtLocal) =>
      isSpanish
          ? 'Inscripciones CERRADAS — fecha límite pasó ($lockAtLocal)'
          : 'Submissions CLOSED — lock time passed ($lockAtLocal)';
  String get adminSubmissionsOpenHint =>
      isSpanish
          ? 'Los jugadores pueden guardar y enviar brackets hasta la fecha límite.'
          : 'Players can save and submit brackets until the lock time.';
  String get adminSubmissionsClosedByAdminHint =>
      isSpanish
          ? 'Usa el interruptor para volver a abrir, o ajusta la fecha límite.'
          : 'Use the switch to reopen, or adjust the lock time.';
  String get adminSubmissionsClosedByLockHint =>
      isSpanish
          ? 'Mueve la fecha límite al futuro y abre inscripciones para reabrir.'
          : 'Move lock time to the future and turn accepting submissions on to reopen.';
  String get saveLockTime => isSpanish ? 'Guardar fecha límite' : 'Save lock time';
  String get closeSubmissionsTitle =>
      isSpanish ? '¿Cerrar inscripciones?' : 'Close submissions?';
  String get closeSubmissionsBody =>
      isSpanish
          ? 'Nadie podrá guardar ni enviar brackets hasta que vuelvas a abrir.'
          : 'Nobody can save or submit brackets until you reopen submissions.';
  String get openSubmissionsTitle =>
      isSpanish ? '¿Abrir inscripciones?' : 'Open submissions?';
  String openSubmissionsBody(String lockAtLocal) =>
      isSpanish
          ? 'Los jugadores podrán editar hasta $lockAtLocal (o hasta que cierres de nuevo).'
          : 'Players can edit until $lockAtLocal (or until you close again).';
  String get autosaveEnabled =>
      isSpanish
          ? 'El autoguardado está activado. Completa cada grupo y cada ronda antes del primer partido.'
          : 'Autosave is enabled. Complete every group and knockout slot before the first kickoff.';
  String get bracketSubmitted =>
      isSpanish
          ? 'Bracket enviado. Puedes seguir editando hasta el bloqueo.'
          : 'Bracket submitted. You can keep editing until lock.';
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
  String get exportPdf => isSpanish ? 'Exportar PDF' : 'Export PDF';
  String pdfBracketTitle(String username) =>
      isSpanish
          ? 'Bracket Mundial 2026 de $username'
          : '$username World Cup 2026 Bracket';
  String get pdfAppCredit =>
      isSpanish ? 'App creada por Ricky' : 'App created by Ricky';
  String get pdfChampion => isSpanish ? 'Campeón' : 'Champion';
  String get pdfGroupPicks =>
      isSpanish ? 'Selecciones de grupo' : 'Group Picks';
  String get pdfFirstPlace => isSpanish ? '1ro' : '1st';
  String get pdfSecondPlace => isSpanish ? '2do' : '2nd';
  String get pdfThirdPlace => isSpanish ? '3ro' : '3rd';
  String get pdfBestThirdColumn => isSpanish ? 'Mejor 3ro' : 'Best 3rd';
  String get pdfYes => isSpanish ? 'Sí' : 'Yes';
  String get pdfTbd => isSpanish ? 'Por definir' : 'TBD';
  String get submittedBracket => isSpanish ? 'Bracket enviado' : 'Submitted';
  String get bracketSubmitSuccess =>
      isSpanish ? 'Bracket enviado.' : 'Bracket submitted.';
  String bracketSubmitFailed(Object error) =>
      isSpanish ? 'No se pudo enviar: $error' : 'Could not submit: $error';
  String get roundOf32 => isSpanish ? 'Ronda de 32' : 'Round of 32';
  String get roundOf16 => isSpanish ? 'Ronda de 16' : 'Round of 16';
  String get quarterfinals => isSpanish ? 'Cuartos de final' : 'Quarterfinals';
  String get semifinals => isSpanish ? 'Semifinales' : 'Semifinals';
  String get finalRound => isSpanish ? 'Final' : 'Final';

  String get playersIntro =>
      isSpanish
          ? 'Ve los brackets enviados por otros jugadores.'
          : 'See submitted brackets from other players.';
  String get noSubmittedBrackets =>
      isSpanish
          ? 'Todavía no hay brackets enviados.'
          : 'No submitted brackets yet.';
  String get publicBracketUnavailable =>
      isSpanish
          ? 'Este bracket no está enviado o no está disponible.'
          : 'This bracket has not been submitted or is unavailable.';

  String get globalLeaderboard =>
      isSpanish ? 'Tabla global' : 'Global leaderboard';
  String get scoringExplainer =>
      isSpanish
          ? 'Grupos: +1 si tu equipo queda en el top 3, +2 extra si aciertas el puesto exacto. Eliminatorias: 1/2/4/8/16 pts (cada ronda vale el doble). El marcador de la final desempata.'
          : 'Groups: +1 if your pick finishes top 3, +2 extra for the exact spot. Knockouts: 1/2/4/8/16 pts (each round doubles). Final score prediction breaks ties.';
  String get rank => isSpanish ? 'Lugar' : 'Rank';
  String get score => isSpanish ? 'Puntos' : 'Score';
  String get tie => isSpanish ? 'Desempate' : 'Tie';

  String get teamsFlagsFixtures =>
      isSpanish ? 'Equipos, banderas y partidos' : 'Teams, flags, and games';
  String get countryDataExplainer =>
      isSpanish
          ? 'Los países usan API-Football como fuente principal con banderas de respaldo incluidas.'
          : 'Country data uses API-Football as the canonical source with bundled fallback flag assets.';
  String get fixtureSyncPreview =>
      isSpanish
          ? 'Vista previa de partidos sincronizados'
          : 'Game sync preview';
  String get vs => isSpanish ? 'contra' : 'vs';
  String get todaysGames => isSpanish ? 'Partidos de hoy' : "Today's games";
  String get amysCalendarIntro =>
      isSpanish
          ? 'Calendario del torneo con partidos, resultados en vivo y filtro por equipo.'
          : 'Tournament calendar with matchdays, live scores, and team filtering.';
  String get filterByTeam =>
      isSpanish ? 'Filtrar por equipo' : 'Filter by team';
  String get allTeams => isSpanish ? 'Todos los equipos' : 'All teams';
  String get totalGamesLabel => isSpanish ? 'partidos totales' : 'total games';
  String get today => isSpanish ? 'Hoy' : 'Today';
  String get previousMonth => isSpanish ? 'Mes anterior' : 'Previous month';
  String get nextMonth => isSpanish ? 'Mes siguiente' : 'Next month';
  String moreGames(int count) => isSpanish ? '+$count más' : '+$count more';
  String get noMatchesOnDate =>
      isSpanish ? 'No hay partidos en esta fecha.' : 'No matches on this date.';
  String get venue => isSpanish ? 'Sede' : 'Venue';
  String get matchStatus => isSpanish ? 'Estado' : 'Status';
  String get winnerLabel => isSpanish ? 'Ganador' : 'Winner';
  String get tbd => isSpanish ? 'Por definir' : 'TBD';

  String get publicProfile => isSpanish ? 'Perfil público' : 'Public profile';
  String get noRecoveryLinked =>
      isSpanish ? 'Cuenta con contraseña' : 'Password account';
  String linked(String providers) =>
      isSpanish ? 'Vinculado: $providers' : 'Linked: $providers';
  String get accountRecovery => isSpanish ? 'Cuenta' : 'Account';
  String get accountRecoveryBody =>
      isSpanish
          ? 'Tu usuario es permanente. Si agregaste correo, puedes restablecer la contraseña desde la pantalla de inicio.'
          : 'Your username is permanent. If you added email, you can reset your password from the sign-in screen.';
  String linkProvider(String provider) =>
      isSpanish ? 'Vincular $provider' : 'Link $provider';
  String get signOut => isSpanish ? 'Cerrar sesión' : 'Sign out';
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
  String get signInRequired =>
      isSpanish ? 'Inicia sesión para continuar' : 'Sign in to continue';
  String get signInRequiredBody =>
      isSpanish
          ? 'Crea una cuenta o inicia sesión para ver esta parte de la app.'
          : 'Create an account or sign in to view this part of the app.';
  String get adminEmailLocked =>
      isSpanish
          ? 'Solo rgw1985@hotmail.com puede acceder como admin.'
          : 'Only rgw1985@hotmail.com can access admin.';
  String get adminProfileLoading =>
      isSpanish
          ? 'Inicio de sesión correcto. Cargando perfil de admin...'
          : 'Sign-in succeeded. Loading admin profile...';
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
      isSpanish ? 'Sincronización de resultados' : 'Score sync';
  String get apiFootballSyncBody =>
      isSpanish
          ? 'La sincronización automática consulta football-data.org solo cerca del horario de los partidos (hasta ~15 min después del final). Usa Sincronizar ahora para actualizaciones inmediatas. Los resultados manuales del admin siempre ganan.'
          : 'Automatic sync polls football-data.org only around game times (up to ~15 minutes after full time). Use Sync now for immediate updates. Manual admin results always win.';
  String get syncNow => isSpanish ? 'Sincronizar' : 'Sync now';
  String get teamsAndFlags =>
      isSpanish ? 'Equipos y banderas' : 'Teams and flags';
  String get teamsAndFlagsBody =>
      isSpanish
          ? 'Corrige nombres, abreviaturas, IDs de API, URLs de bandera y respaldos.'
          : 'Override country names, abbreviations, API IDs, flag URLs, and fallback asset keys.';
  String get reviewTeams => isSpanish ? 'Revisar equipos' : 'Review teams';
  String get fixturesAndResults =>
      isSpanish ? 'Partidos y resultados' : 'Games and results';
  String get fixturesAndResultsBody =>
      isSpanish
          ? 'Corrige horarios, estados, marcadores, ganadores y bloqueo del bracket.'
          : 'Correct kickoff times, statuses, scores, winners, and bracket lock timing.';
  String get reviewFixtures => isSpanish ? 'Revisar partidos' : 'Review games';
  String get moderation => isSpanish ? 'Moderación' : 'Moderation';
  String get moderationBody =>
      isSpanish
          ? 'Revisa reportes, oculta perfiles/brackets abusivos y renombra usuarios.'
          : 'Review reports, hide abusive profiles/brackets, and rename users when needed.';
  String get reviewReports => isSpanish ? 'Revisar reportes' : 'Review reports';
  String loadedCountries(int count) =>
      isSpanish ? 'Países cargados: $count' : 'Loaded countries: $count';
  String loadedFixtures(int count) =>
      isSpanish ? 'Partidos cargados: $count' : 'Loaded games: $count';

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

class StandingsLegendEntry {
  const StandingsLegendEntry(this.abbr, this.label);

  final String abbr;
  final String label;
}
