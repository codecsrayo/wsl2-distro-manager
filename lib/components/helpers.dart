/// Copyright (c) 2023 Eric <eric@bostrot.com>
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.

import 'dart:io';
import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' show join;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wsl2distromanager/api/safe_paths.dart';
import 'package:wsl2distromanager/api/wsl.dart';
import 'package:wsl2distromanager/components/constants.dart';
import 'package:wsl2distromanager/nav/root_screen.dart';

late String language;

// Bandera para activar modo de emergencia (sin preferencias persistentes)
bool emergencyMode = false;

// Objeto SharedPreferences que será inicializado en la función initPrefs
SharedPreferences? _prefs;

// Objeto mockup para usar cuando _prefs es null para evitar errores
class EmptyPrefs implements SharedPreferences {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Para cualquier método que se llame en esta clase, devolvemos un valor predeterminado seguro
    if (invocation.memberName.toString().contains('getString')) {
      return '';
    } else if (invocation.memberName.toString().contains('getBool')) {
      return false;
    } else if (invocation.memberName.toString().contains('getInt')) {
      return 0;
    } else if (invocation.memberName.toString().contains('getDouble')) {
      return 0.0;
    } else if (invocation.memberName.toString().contains('getStringList')) {
      return <String>[];
    }
    return null;
  }
  
  @override
  Set<String> getKeys() => <String>{};
  
  @override
  Object? get(String key) => null;
  
  @override
  bool? getBool(String key) => false;
  
  @override
  double? getDouble(String key) => 0.0;
  
  @override
  int? getInt(String key) => 0;
  
  @override
  String? getString(String key) => '';
  
  @override
  List<String>? getStringList(String key) => <String>[];
  
  @override
  Future<bool> setBool(String key, bool value) async => true;
  
  @override
  Future<bool> setDouble(String key, double value) async => true;
  
  @override
  Future<bool> setInt(String key, int value) async => true;
  
  @override
  Future<bool> setString(String key, String value) async => true;
  
  @override
  Future<bool> setStringList(String key, List<String> value) async => true;
  
  @override
  Future<bool> remove(String key) async => true;
  
  @override
  Future<bool> clear() async => true;
  
  @override
  bool containsKey(String key) => false;
  
  @override
  Future<void> reload() async {}
}

// Getter seguro para prefs que devuelve un objeto EmptyPrefs si aún no está inicializado
SharedPreferences get prefs {
  // Si el modo de emergencia está activado, siempre usar preferencias vacías
  if (emergencyMode) {
    print('MODO DE EMERGENCIA: Usando preferencias vacías en memoria para evitar errores de persistencia');
    return EmptyPrefs();
  }
  
  // Comportamiento normal (si no estamos en modo de emergencia)
  if (_prefs == null) {
    print('ADVERTENCIA: Se accedió a prefs antes de la inicialización. Usando preferencias vacías.');
    return EmptyPrefs();
  }
  return _prefs!;
}

bool initialized = false;

/// Get distro label from [item].
String distroLabel(String item) {
  // Acceso seguro a las preferencias
  try {
    String? distroName = prefs.getString('DistroName_$item');
    if (distroName == null || distroName == '') {
      distroName = item;
    }
    return distroName;
  } catch (e) {
    print('Error al obtener distroLabel: $e');
    return item;
  }
}

/// Replace special characters in [name] with underscores.
String replaceSpecialChars(String name) {
  return name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
}

/// Initialize shared preferences
Future<void> initPrefs() async {
  initialized = false;
  try {
    // Para evitar asumir que existe un archivo de preferencias corrupto
    // intentamos inicializar SharedPreferences con manejo de errores
    SharedPreferences tempPrefs;
    
    try {
      // Inicialización normal sin limpieza previa
      tempPrefs = await SharedPreferences.getInstance();
      print('Preferencias obtenidas exitosamente');
      
      // Validar la integridad de las preferencias existentes
      final problemaEnPrefs = await _verificarIntegridadPrefs(tempPrefs);
      
      if (problemaEnPrefs) {
        print('Se detectaron problemas en las preferencias, realizando limpieza');
        // Si hay problemas, limpiamos todo excepto el idioma
        String? savedLang;
        try {
          savedLang = tempPrefs.getString('languageCode');
        } catch (e) {
          print('No se pudo recuperar idioma: $e');
        }
        
        // Limpieza total
        await tempPrefs.clear();
        print('Preferencias limpiadas completamente');
        
        // Restaurar solo el idioma si es válido
        if (savedLang != null && _esCodigoIdiomaValido(savedLang)) {
          await tempPrefs.setString('languageCode', savedLang);
          print('Idioma restaurado: $savedLang');
        }
      }
    } catch (e) {
      print('Error al obtener SharedPreferences: $e');
      // Si falla la inicialización, creamos una instancia limpia
      // pero primero intentamos limpiar cualquier dato existente
      try {
        final flutterDir = Directory(join(
            Platform.environment['LOCALAPPDATA'] ?? '',
            'flutter_tools.wsl2distromanager'));
        
        if (await flutterDir.exists()) {
          print('Intentando limpiar directorio de preferencias');
          // Limpiamos el directorio de preferencias de Flutter
          await for (final entity in flutterDir.list()) {
            try {
              if (entity is File && entity.path.contains('shared_preferences')) {
                await entity.delete();
                print('Archivo eliminado: ${entity.path}');
              }
            } catch (e) {
              print('Error al eliminar archivo: $e');
            }
          }
        }
      } catch (e) {
        print('Error al limpiar archivos de preferencias: $e');
      }
      
      // Intentamos nuevamente después de la limpieza
      try {
        tempPrefs = await SharedPreferences.getInstance();
        print('SharedPreferences reinicializado correctamente');
      } catch (e) {
        print('Error fatal en SharedPreferences: $e');
        _prefs = EmptyPrefs();
        return;
      }
    }
    
    // Si llegamos aquí, tenemos preferencias inicializadas correctamente
    _prefs = tempPrefs;
    print('Preferencias inicializadas correctamente');
  } catch (e) {
    print('Error crítico al inicializar preferencias: $e');
    // Usar preferencias vacías como último recurso
    _prefs = EmptyPrefs();
  } finally {
    initialized = true;
  }
}

/// Verifica si hay problemas en las preferencias existentes
Future<bool> _verificarIntegridadPrefs(SharedPreferences prefs) async {
  try {
    // Intentamos acceder a valores clave para verificar integridad
    final keys = prefs.getKeys();
    for (final key in keys) {
      try {
        // Verificar cada valor dependiendo de su tipo
        final type = prefs.get(key).runtimeType;
        if (type == String) {
          prefs.getString(key);
        } else if (type == bool) {
          prefs.getBool(key);
        } else if (type == int) {
          prefs.getInt(key);
        } else if (type == double) {
          prefs.getDouble(key);
        } else if (type == List) {
          prefs.getStringList(key);
        }
      } catch (e) {
        print('Problema detectado en clave: $key - $e');
        return true; // Hay problemas
      }
    }
    return false; // No se detectaron problemas
  } catch (e) {
    print('Error al verificar integridad: $e');
    return true; // Por seguridad, asumimos que hay problemas
  }
}

/// Verifica si un código de idioma es válido
bool _esCodigoIdiomaValido(String code) {
  return code.isNotEmpty && 
         code.length <= 5 && 
         RegExp(r'^[a-z]{2}(_[A-Z]{2})?$').hasMatch(code);
}

/// Repara preferencias corruptas eliminando valores JSON inválidos
Future<void> _repairCorruptedPrefs() async {
  if (_prefs == null) return;
  
  // Claves importantes que podrían contener JSON
  final jsonKeys = ['distros', 'config', 'languageCode', 'selectedLang'];
  
  for (var key in jsonKeys) {
    if (_prefs!.containsKey(key)) {
      try {
        final value = _prefs!.getString(key);
        if (value != null && value.isNotEmpty) {
          // Verificar si es un JSON válido intentando parsearlo
          try {
            json.decode(value);
          } catch (e) {
            // JSON inválido, eliminar clave corrupta
            print('Reparando preferencia corrupta: $key');
            await _prefs!.remove(key);
          }
        }
      } catch (e) {
        print('Error al verificar clave $key: $e');
        await _prefs!.remove(key);
      }
    }
  }
}

/// Global variables for global context access.
class GlobalVariable {
  static final GlobalKey<RootPageState> root = GlobalKey<RootPageState>();
  static GlobalKey<NavigatorState> infobox = GlobalKey<NavigatorState>();
  static Instances? initialSnapshot;
  static Function? refreshListCallback;
}

/// Return the general distro path. Distros are saved here by default.
/// It will be created if it does not exist.
///
/// e.g. C:\WSL2-Distros\distros
SafePath getDistroPath() {
  String path = prefs.getString('DistroPath') ?? defaultPath;
  return SafePath(path)..cd('distros');
}

/// Get the tmp folder path. This is used for the download of docker layers.
/// It will be created if it does not exist.
///
/// e.g. C:\WSL2-Distros\tmp
SafePath getTmpPath() {
  return getDistroPath()
    ..cdUp()
    ..cd('tmp');
}

/// Get the instance path for the [name] instance.
/// It will be created if it does not exist.
///
/// e.g. C:\WSL2-Distros\ubuntu
SafePath getInstancePath(String name) {
  String? instanceLocation = prefs.getString('Path_$name');
  if (instanceLocation != null && instanceLocation.isNotEmpty) {
    // Fix path for older versions
    var safePath = SafePath(instanceLocation);
    prefs.setString('Path_$name', safePath.path);
    return safePath;
  }
  return getDistroPath()
    ..cdUp()
    ..cd(name);
}

/// Get instance size for [name] instance.
String getInstanceSize(String name) {
  var path = getInstancePath(name).file('ext4.vhdx');
  try {
    var size = File(path).lengthSync();

    if (size > 0) {
      var sizeGB = size / 1024 / 1024 / 1024;
      return '${sizeGB.toStringAsFixed(2)} GB';
    } else {
      return '';
    }
  } catch (e) {
    return '';
  }
}

/// Get the wslconfig path
String getWslConfigPath() {
  return SafePath('C:\\Users\\${Platform.environment['USERNAME']}')
      .file('.wslconfig');
}
