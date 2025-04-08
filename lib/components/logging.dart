/// Simple file-based logging and error reporting

import 'dart:io';

// No necesitamos dio para la versión local
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:wsl2distromanager/api/safe_paths.dart';
import 'package:wsl2distromanager/components/analytics.dart';
import 'package:wsl2distromanager/components/constants.dart';
import 'package:wsl2distromanager/components/helpers.dart';

/// Get log file path
String getLogFilePath() {
  return (SafePath(Platform.environment['APPDATA']!)
        ..cd('com.bostrot')
        ..cd('WSL Distro Manager'))
      .file('wslmanager_01.log');
}

/// Initialize logging
void initLogging() async {
  // Log file
  var logfile = File(getLogFilePath());
  // Delete if file is larger than 1MB
  if (await logfile.exists() && await logfile.length() > 10 * 1024 * 1024) {
    await logfile.delete();
  }

  // File does not contain current version
  if (await logfile.exists() &&
      !(await logfile.readAsString()).contains(currentVersion)) {
    await logfile.delete();
  }

  // Check if file exists
  if (!await logfile.exists()) {
    await logfile.create();
    // Write header with version info and OS info
    await logfile.writeAsString(
        'WSL Manager v$currentVersion on ${Platform.operatingSystem} '
        '${Platform.operatingSystemVersion}\r\n\r\n'
        '============================================================'
        '\r\n\r\n');
  }
}

/// Log a debug message to file
void logDebug(Object error, StackTrace? stack, String? library) {
  // Log to file
  logInfo('$error at $stack in $library');
}

/// Log a message to file
void logInfo(String msg) {
  // Append to file
  File(getLogFilePath()).writeAsStringSync(msg, mode: FileMode.append);
}

/// Log an error to file
void logError(Object error, StackTrace? stack, String? library) {
  // Print to console
  if (kDebugMode) {
    print('$error at $stack in $library');
    return;
  }
  // Log to file
  logInfo('$error at $stack in $library');
  // Send to webhook if analytics are enabled
  if (!plausible.enabled) return;
}

/// Manually trigger upload of log file
void uploadLog() async {
  try {
    var file = File(getLogFilePath());
    if (!await file.exists()) {
      // Mostrar mensaje al usuario de que no hay archivo de log
      final context = GlobalVariable.infobox.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('Error'),
            content: const Text('No se encontró el archivo de registro. No hay registros para guardar.'),
            actions: [
              Button(
                child: const Text('Aceptar'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Date only
    var date = DateTime.now().toIso8601String().split('T')[0];
    var time = DateTime.now().toIso8601String().split('T')[1].split('.')[0].replaceAll(':', '-');
    
    // Generar nombre de archivo con fecha y hora
    var fileName = 'WSL2-Distro-Manager-Log-$date-$time.txt';
    
    // Obtener directorio de Descargas
    final Directory downloadsDir = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }
    
    // Crear copia del archivo en Descargas
    final String destinationPath = '${downloadsDir.path}\\$fileName';
    await file.copy(destinationPath);
    
    // Mostrar mensaje de éxito
    final context = GlobalVariable.infobox.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Éxito'),
          content: Text('El archivo de registro se ha guardado en:\n$destinationPath'),
          actions: [
            Button(
              child: const Text('Aceptar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    
    // Registrar acción de guardado de log
    logInfo('Log file saved to $destinationPath');
  } catch (e, stack) {
    // Registrar error
    logError(e, stack, 'uploadLog');
    
    // Mostrar mensaje de error
    final context = GlobalVariable.infobox.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Error'),
          content: Text('No se pudo guardar el archivo de registro: $e'),
          actions: [
            Button(
              child: const Text('Aceptar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }
}
