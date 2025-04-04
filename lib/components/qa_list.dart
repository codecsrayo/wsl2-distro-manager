import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:localization/localization.dart';
import 'package:wsl2distromanager/api/quick_actions.dart';
import 'package:wsl2distromanager/components/constants.dart';
import 'package:wsl2distromanager/components/hoverable.dart';
import 'package:wsl2distromanager/components/notify.dart';
import 'package:wsl2distromanager/theme.dart';

/// Community Quick Actions List
class QaList extends StatefulWidget {
  const QaList({Key? key}) : super(key: key);

  @override
  State<QaList> createState() => QaListState();
}

class QaListState extends State<QaList> {
  String? filter;
  List<QuickActionItem> selectedList = [];
  static List<QuickActionItem> items = [];

  /// Toggle selected item
  void toggleItem(QuickActionItem item) {
    if (selectedList.contains(item)) {
      selectedList.remove(item);
    } else {
      selectedList.add(item);
    }
    setState(() {});
  }

  /// Download the current selection
  Future download() async {
    if (kDebugMode) {
      print("downloading...");
    }

    // Load data from git repos
    try {
      for (var i = 0; i < selectedList.length; i++) {
        String name = selectedList[i].name;
        QuickActionItem item = selectedList[i];
        String repoToUse;
        
        // Determinar de qué repositorio descargar basado en la descripción
        // Si contiene [Personal], usar el repositorio personal
        if (item.description.contains("[Personal]")) {
          repoToUse = repoScriptsPersonal;
        } else {
          repoToUse = repoScriptsOriginal;
        }
        
        // Get Script
        Response<dynamic> contentFile =
            await Dio().get('$repoToUse/$name/script.noshell');
        item.content = contentFile.data.toString();
        QuickAction.addToPrefs(item);
      }
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
      Notify.message('errordownloading-text'.i18n());
    }
  }

  /// Get the list of scripts from the repos (original and personal)
  Future<List<QuickActionItem?>> _getQuickActionsFromRepo() async {
    // Use cache
    if (items.isNotEmpty) {
      return items;
    }
    // Intentar cargar scripts del repositorio original
    try {
      // Cargar scripts del repositorio original
      Response<dynamic> repo = await Dio().get(gitApiScriptsLinkOriginal);
      List<dynamic> repoData = repo.data;
      for (var i = 0; i < repoData.length; i++) {
        String name = repoData[i]["name"];
        try {
          // Get script metadata
          Response<dynamic> infoFileResponse =
              await Dio().get('$repoScriptsOriginal/$name/info.yml');
          // Save metadata to list
          items.add(
              QuickActionItem.fromYamlString(infoFileResponse.data.toString()));
        } catch (innerErr) {
          // Ignorar errores individuales para continuar con el siguiente script
          if (kDebugMode) {
            print("Error cargando script original: $name - $innerErr");
          }
        }
      }
    } catch (err) {
      if (kDebugMode) {
        print("Error cargando repositorio original: $err");
      }
      // Continuar incluso si hay error, para intentar con el repositorio personal
    }
    
    // Intentar cargar scripts del repositorio personal
    try {
      // Cargar scripts del repositorio personal
      Response<dynamic> repoPersonal = await Dio().get(gitApiScriptsLinkPersonal);
      List<dynamic> repoDataPersonal = repoPersonal.data;
      for (var i = 0; i < repoDataPersonal.length; i++) {
        // Solo procesar directorios, ignorar archivos individuales
        if (repoDataPersonal[i]["type"] != "dir") continue;
        
        String name = repoDataPersonal[i]["name"];
        try {
          // Get script metadata
          Response<dynamic> infoFileResponse =
              await Dio().get('$repoScriptsPersonal/$name/info.yml');
              
          try {
            // Intentar parsear el YAML con manejo de errores adicional
            var item = QuickActionItem.fromYamlString(infoFileResponse.data.toString());
            // Añadir prefijo al nombre para distinguir y evitar conflictos
            item.description = "${item.description} [Personal]";
            items.add(item);
            if (kDebugMode) {
              print("Script personal cargado exitosamente: $name");
            }
          } catch (yamlErr) {
            if (kDebugMode) {
              print("Error parseando YAML del script personal: $name - $yamlErr");
              print("Contenido YAML problematico: ${infoFileResponse.data.toString()}");
            }
          }
        } catch (innerErr) {
          // Ignorar errores individuales para continuar con el siguiente script
          if (kDebugMode) {
            print("Error cargando script personal: $name - $innerErr");
          }
        }
      }
    } catch (err) {
      if (kDebugMode) {
        print("Error cargando repositorio personal: $err");
      }
      // No lanzar excepción si falló el repositorio personal pero se cargaron scripts originales
      if (items.isEmpty) {
        throw Exception("No se pudieron cargar scripts de ningún repositorio");
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: TextBox(
            placeholder: 'search-text'.i18n(),
            onChanged: (value) {
              setState(() {
                filter = value;
              });
            },
          ),
        ),
        Expanded(child: listView(filter: filter))
      ],
    );
  }

  FutureBuilder<List<QuickActionItem?>> listView({String? filter}) {
    return FutureBuilder(
        future: _getQuickActionsFromRepo(),
        builder: (BuildContext context,
            AsyncSnapshot<List<QuickActionItem?>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (BuildContext context, int index) {
                  if (snapshot.data![index] == null ||
                      (filter != null &&
                          filter.isNotEmpty &&
                          (!snapshot.data![index]!.name
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()) &&
                              !snapshot.data![index]!.description
                                  .toLowerCase()
                                  .contains(filter.toLowerCase())))) {
                    return Container();
                  }
                  var data = snapshot.data![index]!;
                  return Hoverable(
                    child: ListTile(
                      tileColor: ButtonState.all(selectedList.contains(data)
                          ? AppTheme().color.withOpacity(0.5)
                          : Colors.transparent),
                      title: Text(data.name),
                      subtitle: Text(data.description),
                      onPressed: () => toggleItem(data),
                    ),
                  );
                });
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ProgressRing());
          } else {
            return Center(child: Text('errordownloading-text'.i18n()));
          }
        });
  }
}
