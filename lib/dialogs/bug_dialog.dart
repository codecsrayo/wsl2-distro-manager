import 'package:fluent_ui/fluent_ui.dart';
import 'package:localization/localization.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wsl2distromanager/components/analytics.dart';
import 'package:wsl2distromanager/components/constants.dart';
import 'package:wsl2distromanager/components/helpers.dart';
import 'package:wsl2distromanager/components/logging.dart';

/// Bug dialog
bugDialog() {
  // Get root context by Key
  final context = GlobalVariable.infobox.currentContext!;

  plausible.event(page: 'bug_dialog');
  // Show dialog that asks if the user wants to upload the log file or just open a github issue or cancel
  showDialog(
    context: context,
    builder: (context) => ContentDialog(
      title: const Text('🐞 Bug Report'),
      content: Text('report-text'.i18n()),
      actions: [
        SizedBox(
          height: 50.0,
          child: Button(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('cancelreport-text'.i18n()),
          ),
        ),
        SizedBox(
          height: 50.0,
          child: Button(
            onPressed: () async {
              Navigator.of(context).pop();
              // Intentar abrir github issue con manejo mejorado de errores
              try {
                final Uri url = Uri.parse(githubIssues);
                final bool launched = await launchUrlString(
                  url.toString(),
                  mode: LaunchMode.externalApplication,
                );
                
                if (!launched) {
                  // Mostrar mensaje si no se pudo abrir el navegador
                  final BuildContext appContext = GlobalVariable.infobox.currentContext!;
                  showDialog(
                    context: appContext,
                    builder: (context) => ContentDialog(
                      title: const Text('Error'),
                      content: Text('No se pudo abrir: $githubIssues\n\nPor favor, copia esta URL y ábrela manualmente en tu navegador.'),
                      actions: [
                        Button(
                          child: const Text('Aceptar'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                // Capturar y mostrar cualquier error
                final BuildContext appContext = GlobalVariable.infobox.currentContext!;
                showDialog(
                  context: appContext,
                  builder: (context) => ContentDialog(
                    title: const Text('Error'),
                    content: Text('Error al abrir URL: $e'),
                    actions: [
                      Button(
                        child: const Text('Aceptar'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text('githubissue-text'.i18n()),
          ),
        ),
        SizedBox(
          height: 50.0,
          child: Button(
            onPressed: () {
              Navigator.of(context).pop();
              // Upload log file
              uploadLog();
            },
            child: Text('generatelog-text'.i18n()),
          ),
        ),
      ],
    ),
  );
}
