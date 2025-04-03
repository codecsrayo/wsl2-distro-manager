import 'dart:async';

import 'package:localization/localization.dart';
import 'package:wsl2distromanager/api/wsl.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:wsl2distromanager/dialogs/dialogs.dart';
import 'list_item.dart';
import 'helpers.dart';

/// The widget of distros in the main page. This is being refreshed every 5
/// seconds using the reloadEvery5Seconds() function.
class DistroList extends StatefulWidget {
  const DistroList({Key? key, required this.api}) : super(key: key);

  final WSLApi api;

  @override
  DistroListState createState() => DistroListState();
}

class DistroListState extends State<DistroList> {
  Map<String, bool> hover = {};
  bool isSyncing = false;
  bool showDocker = false;

  void syncing(var item) {
    if (mounted) {
      setState(() {
        isSyncing = item;
      });
    }
  }

  void init() async {
    await initPrefs();
    // Get shared prefs for showing docker containers
    showDocker = prefs.getBool('showDocker') ?? false;
    if (mounted) {
      setState(() {});
    }
    reloadEvery5Seconds();
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  void reloadEvery5Seconds() async {
    for (;;) {
      await Future.delayed(const Duration(seconds: 5));
      // Check if state disposed
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Agregar identificador para depurar
    debugPrint('Build de DistroList ejecutándose, hora: ${DateTime.now().toString()}');
      
    // Verificar si tenemos un snapshot cacheado para usar
    if (GlobalVariable.initialSnapshot == null) {
      // Forzar una actualización inmediata de la lista
      debugPrint('initialSnapshot es null, solicitando nueva lista de WSL');
    }
    
    // List as FutureBuilder with WSLApi
    return FutureBuilder<Instances>(
      future: widget.api.list(showDocker),
      initialData: GlobalVariable.initialSnapshot,
      builder: (context, snapshot) {
        // Guardar el resultado para futuras referencias
        if (snapshot.hasData) {
          // Imprimir información del snapshot para depuración
          debugPrint('Snapshot tiene datos: ${snapshot.data?.all.length} distribuciones');
          
          // Guardar datos en variable global para persistencia
          GlobalVariable.initialSnapshot = snapshot.data;
          
          List<Widget> newList = [];
          List<String> list = snapshot.data?.all ?? [];
          List<String> running = snapshot.data?.running ?? [];
          
          // Check if there are distros
          if (list.isEmpty) {
            debugPrint('Lista de distribuciones está vacía');
            return Expanded(
              child: Center(
                child: Text('noinstancesfound-text'.i18n()),
              ),
            );
          }
          
          // Check if WSL is installed
          if (list[0] == 'wslNotInstalled') {
            debugPrint('WSL no está instalado');
            return const InstallDialog();
          }
          
          // Asegurar que siempre tengamos elementos visibles
          debugPrint('Creando ${list.length} elementos de lista para mostrar');
          for (String item in list) {
            newList.add(
              Container(
                // Añadimos un key único basado en el nombre para preservar el estado
                key: Key('distro-$item'),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListItem(
                  item: item,
                  running: running,
                  trailing: getInstanceSize(item),
                ),
              )
            );
          }
          
          // Usar Column para mostrar un encabezado permanente
          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado que siempre será visible
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text(
                    '${list.length} distros',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                ),
                // Lista con los elementos
                Expanded(
                  child: ListView.custom(
                    childrenDelegate: SliverChildListDelegate(newList),
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        // By default, show a loading spinner.
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Center(child: ProgressRing()),
        );
      },
    );
  }
}
