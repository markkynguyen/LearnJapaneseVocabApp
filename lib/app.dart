import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/audio/audio_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class JVocabApp extends ConsumerWidget {
  const JVocabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(audioPreparationProvider);
    ref.listen(audioErrorProvider, (_, next) {
      next.whenData((message) {
        final messenger = _scaffoldMessengerKey.currentState;
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade700,
            ),
          );
      });
    });

    if (ref.watch(currentSessionProvider) != null) {
      ref.listen(appSettingsProvider, (_, next) {
        next.whenData(
          (settings) => ref
              .read(notificationControllerProvider.notifier)
              .syncWithSettings(settings),
        );
      });
    }
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Nana App',
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
