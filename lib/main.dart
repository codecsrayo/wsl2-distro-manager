import 'dart:async';
import 'dart:io' show exit;

import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:localization/localization.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';
import 'package:wsl2distromanager/components/constants.dart';
import 'package:wsl2distromanager/components/error_screen.dart';
import 'package:wsl2distromanager/components/helpers.dart';
import 'package:wsl2distromanager/components/logging.dart';
import 'package:wsl2distromanager/nav/router.dart';

import 'theme.dart';

String appTitle = "WSL Manager v$currentVersion";

/// Checks if the current environment is a desktop environment.
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

// Registro de errores para centralizar el manejo
List<String> _errorLogs = [];
void _registrarError(String mensaje) {
  print(mensaje);
  _errorLogs.add('[${DateTime.now().toIso8601String()}] $mensaje');
}

// Función para mostrar la pantalla de error
void _mostrarPantallaError(String mensaje, String? stackTrace) {
  final String logsCompletos = _errorLogs.join('\n');
  runApp(ErrorScreen(
    errorMessage: mensaje,
    stackTrace: '${stackTrace ?? 'No disponible'}\n\nRegistro de errores:\n$logsCompletos',
    onClose: () {
      exit(1); // Salir de la aplicación
    },
  ));
}

void main() async {
  // Capturar todos los errores asíncronos con runZonedGuarded
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    _registrarError('Aplicación inicializando');
    
    // if it's not on the web, windows or android, load the accent color
    if (!kIsWeb &&
        [
          TargetPlatform.windows,
          TargetPlatform.android,
        ].contains(defaultTargetPlatform)) {
      SystemTheme.accentColor.load();
    }

    if (isDesktop) {
      _registrarError('Configurando ventana de aplicación de escritorio');
      await flutter_acrylic.Window.initialize();
      await flutter_acrylic.Window.hideWindowControls();
      await WindowManager.instance.ensureInitialized();
      windowManager.waitUntilReadyToShow().then((_) async {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
        await windowManager.setMinimumSize(const Size(574, 450));
        await windowManager.setSize(const Size(700, 500));
        await windowManager.show();
        await windowManager.setPreventClose(true);
        await windowManager.setSkipTaskbar(false);
      });
    }

    // Init logging
    initLogging();
    _registrarError('Sistema de logging inicializado');
    
    // Esperar a que las preferencias se inicialicen completamente
    try {
      _registrarError('Intentando inicializar preferencias...');
      await initPrefs();
      _registrarError('Preferencias inicializadas correctamente');
    } catch (e, stack) {
      _registrarError('Error inicializando preferencias: $e');
      _registrarError('Stack trace: $stack');
      // En lugar de continuar, mostramos la pantalla de error
      _mostrarPantallaError(
        'Error crítico al inicializar preferencias: $e', 
        stack.toString()
      );
      return; // No continuamos con la inicialización
    }

    // Error logging
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      logError(details.exception, details.stack, details.library);
      _registrarError('Error en Flutter: ${details.exception}');
      _registrarError('Stack trace: ${details.stack}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      logError(error, stack, null);
      _registrarError('Error en la plataforma: $error');
      _registrarError('Stack trace: $stack');
      return true;
    };

    // Set version
    await PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      currentVersion = packageInfo.version;
      _registrarError('Versión de la aplicación: $currentVersion');
    });

    // Init app
    _registrarError('Iniciando la aplicación normal');
    runApp(const WSLManager());
  }, (error, stackTrace) {
    // Capturar cualquier error no manejado
    _registrarError('ERROR CRÍTICO NO MANEJADO: $error');
    _registrarError('Stack trace: $stackTrace');
    _mostrarPantallaError(
      'Error crítico no manejado: $error',
      stackTrace.toString()
    );
  });
}

class WSLManager extends StatelessWidget {
  const WSLManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    LocalJsonLocalization.delegate.directories = ['lib/i18n'];
    return ChangeNotifierProvider(
      create: (_) => AppTheme(),
      builder: (context, _) {
        // Wait for prefs to be initialized
        while (!initialized) {}
        final appTheme = context.watch<AppTheme>();
        var selectedLang = prefs.getString('language');
        return FluentApp.router(
          title: appTitle,
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          color: appTheme.color,
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          theme: FluentThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          locale: appTheme.locale,
          localeResolutionCallback: (locale, supportedLocales) {
            // Language was set manually
            if (selectedLang != null && selectedLang.isNotEmpty) {
              language = selectedLang;
              if (language == "zh") {
                return const Locale('zh', 'CN');
              }
              // Validar que selectedLang sea un código de idioma válido
              // Solo usar los códigos más comunes y seguros
              final validLanguages = ['en', 'es', 'de', 'fr', 'it', 'pt', 'ru', 'ja', 'ko'];
              if (validLanguages.contains(selectedLang)) {
                return Locale(selectedLang);
              } else {
                // Si no es válido, usar inglés como fallback
                print('Código de idioma inválido: $selectedLang, usando inglés como alternativa');
                language = 'en';
                return const Locale('en', '');
              }
            }

            if (locale == null) {
              language = 'en';
              return const Locale('en', '');
            }
            language = locale.toLanguageTag();
            if (supportedLocales.contains(locale)) {
              return locale;
            }

            // Custom matching for chinese (simplified and traditional)
            if (language.toLowerCase().contains("hans")) {
              return const Locale('zh', 'CN');
            } else if (language.toLowerCase().contains("hant")) {
              return const Locale('zh', 'TW');
            } else if (locale.languageCode == "zh") {
              return const Locale('zh', 'CN');
            }

            // No exact match, try language only
            final Locale lang = Locale(locale.languageCode, '');
            if (supportedLocales.contains(lang)) {
              return lang;
            }

            // default language
            return const Locale('en', '');
          },
          localizationsDelegates: [
            LocalJsonLocalization.delegate,
          ],
          supportedLocales: supportedLocalesList,
          builder: (context, child) {
            return Directionality(
              textDirection: appTheme.textDirection,
              child: NavigationPaneTheme(
                data: NavigationPaneThemeData(
                  backgroundColor: appTheme.windowEffect !=
                          flutter_acrylic.WindowEffect.disabled
                      ? Colors.transparent
                      : null,
                ),
                child: child!,
              ),
            );
          },
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          routeInformationProvider: router.routeInformationProvider,
        );
      },
    );
  }
}
