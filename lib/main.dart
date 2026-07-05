import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/cloud/supabase_config.dart';
import 'core/router/app_url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAppUrlStrategy();

  await Supabase.initialize(
    url: SupabaseConfig.isConfigured
        ? SupabaseConfig.url
        : 'https://example.supabase.co',
    publishableKey: SupabaseConfig.isConfigured
        ? SupabaseConfig.publishableKey
        : 'not-configured',
  );

  runApp(
    const ProviderScope(
      child: JVocabApp(),
    ),
  );
}
