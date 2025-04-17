import 'package:localization/localization.dart';
import 'package:wsl2distromanager/api/templates.dart';
import 'package:wsl2distromanager/api/wsl.dart';
import 'package:wsl2distromanager/components/notify.dart';
import 'package:wsl2distromanager/components/constants.dart';
import 'analytics.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:wsl2distromanager/components/helpers.dart';
import 'package:wsl2distromanager/dialogs/dialogs.dart';
import 'package:file_picker/file_picker.dart';

/// Builder for the WSL Distro List Items. Each item is an expander with [item]
/// as the title and [trailing] as the trailing text. [running] is a list of
/// running distros.
class ListItem extends StatefulWidget {
  const ListItem(
      {Key? key,
      required this.item,
      required this.running,
      required this.trailing})
      : super(key: key);
  final List<String> running;
  final String item;
  final String trailing;
  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  Map<String, bool> hover = {};
  bool isSyncing = false;
  bool showBar = false;
  bool hovered = false;

  void syncing(var item) {
    setState(() {
      isSyncing = item;
    });
  }

  isRunning(String distroName, List<String> runningList) {
    if (runningList.contains(distroName)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 12.0, right: 12.0),
      child: Expander(
          initiallyExpanded: false,
          leading: Row(children: [
            Tooltip(
              message: 'start-text'.i18n(),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: IconButton(
                  icon: const Icon(FluentIcons.play),
                  onPressed: () {
                    startInstance();
                  },
                ),
              ),
            ),
            isRunning(widget.item, widget.running)
                ? Tooltip(
                    message: 'stop-text'.i18n(),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: IconButton(
                        icon: const Icon(FluentIcons.stop),
                        onPressed: () {
                          stopInstance();
                        },
                      ),
                    ),
                  )
                : const Text(''),
          ]),
          header: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isRunning(widget.item, widget.running)
                  ? (Text(
                      '${distroLabel(widget.item)} (${'running-text'.i18n()})'))
                  : Text(distroLabel(widget.item)),
              Text(widget.trailing),
            ],
          ),
          content: Bar(
            widget: widget,
          )),
    );
  }

  void stopInstance() {
    plausible.event(name: "wsl_stopped");
    WSLApi().stop(widget.item);
    Notify.message('${widget.item} ${'stopped-text'.i18n()}.',
        loading: false, duration: const Duration(seconds: 3));
  }

  void startInstance() {
    plausible.event(name: "wsl_started");
    String? startPath = prefs.getString('StartPath_${widget.item}') ?? '';
    String? startName = prefs.getString('StartUser_${widget.item}') ?? '';
    String startCmd = '';
    if (prefs.getBool('TurnkeyFirstStart_${widget.item}') ?? false) {
      startCmd = 'turnkey-init';
      prefs.setBool('TurnkeyFirstStart_${widget.item}', false);
    } else {
      startCmd = prefs.getString('StartCmd_${widget.item}') ?? '';
      // Replace faulty semicolons (e.g. "; ;" or ";;")
      startCmd = startCmd.replaceAll(RegExp(r';[ ]*;'), ';');
    }
    // Normal start
    WSLApi().start(widget.item,
        startPath: startPath, startUser: startName, startCmd: startCmd);

    Future.delayed(
        const Duration(milliseconds: 500),
        Notify.message('${widget.item} ${'started-text'.i18n()}.',
            duration: const Duration(seconds: 3)));
  }
}

class Bar extends StatelessWidget {
  const Bar({Key? key, required this.widget}) : super(key: key);

  final ListItem widget;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(5.0),
              bottomRight: Radius.circular(5.0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(builder: (childcontext) {
            // Quick actions
            List<MenuFlyoutItem> actions = [];
            List<String>? quickSettingsTitles =
                prefs.getStringList("quickSettingsTitles");
            List<String>? quickSettingsContents =
                prefs.getStringList("quickSettingsContents");
            String? user = prefs.getString('StartUser_${widget.item}');
            if (quickSettingsContents != null && quickSettingsTitles != null) {
              for (int i = 0; i < quickSettingsTitles.length; i++) {
                actions.add(MenuFlyoutItem(
                  leading: const MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(FluentIcons.play),
                    ),
                  ),
                  onPressed: () async {
                    plausible.event(name: "wsl_quickaction_run");
                    WSLApi().runCmds(
                        widget.item, quickSettingsContents[i].split('\n'),
                        user: user);
                  },
                  text: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(quickSettingsTitles[i])),
                ));
              }
            }
            return actions.isNotEmpty
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: DropDownButton(
                      leading: const Icon(FluentIcons.code),
                      title: Text('runquickaction-text'.i18n()),
                      items: actions,
                    ),
                  )
                : const SizedBox();
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Tooltip(
                message: 'saveastemplate-text'.i18n(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(FluentIcons.save_template, size: 16.0),
                    onPressed: () async {
                      await Templates().saveTemplate(widget.item);
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'openwithexplorer-text'.i18n(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(FluentIcons.open_folder_horizontal,
                        size: 16.0),
                    onPressed: () {
                      plausible.event(name: "wsl_explorer");
                      WSLApi().startExplorer(widget.item);
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'openwithvscode-text'.i18n(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(FluentIcons.visual_studio_for_windows,
                        size: 16.0),
                    onPressed: () {
                      plausible.event(name: "wsl_vscode");
                      // Get path
                      String? path =
                          prefs.getString('StartPath_${widget.item}') ?? '';
                      WSLApi().startVSCode(widget.item, path: path);
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'copy-text'.i18n(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(FluentIcons.copy, size: 16.0),
                    onPressed: () {
                      copyDialog(widget.item);
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'rename-text'.i18n(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(FluentIcons.rename, size: 16.0),
                    onPressed: () {
                      dialog(
                          item: widget.item,
                          title:
                              '${'rename-text'.i18n()} \'${distroLabel(widget.item)}\'',
                          body: 'renameinfo-text'.i18n(),
                          submitText: 'rename-text'.i18n(),
                          submitStyle: const ButtonStyle(),
                          onSubmit: (inputText) {
                            Notify.message(
                                'renaminginstance-text'.i18n(
                                    [distroLabel(widget.item), inputText]),
                                loading: true);
                            prefs.setString(
                                'DistroName_${widget.item}', inputText);
                            Notify.message('renamedinstance-text'
                                .i18n([distroLabel(widget.item), inputText]));
                          });
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'cleanup-text'.i18n(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                      icon: const Icon(FluentIcons.broom, size: 16.0),
                      onPressed: () {
                        dialog(
                            item: widget.item,
                            title: 'cleanuptitle-text'.i18n([widget.item]),
                            body: 'cleanupbody-text'.i18n(),
                            submitText: 'continue-text'.i18n(),
                            submitStyle: ButtonStyle(
                              backgroundColor: ButtonState.all(Colors.red),
                              foregroundColor: ButtonState.all(Colors.white),
                            ),
                            submitInput: false,
                            cancelText: 'cancel-text'.i18n(),
                            onSubmit: (inputText) {
                              WSLApi().cleanup(widget.item);
                            });
                      }),
                ),
              ),
              Tooltip(
                message: 'delete-text'.i18n(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                      icon: const Icon(FluentIcons.delete, size: 16.0),
                      onPressed: () {
                        dialog(
                            item: widget.item,
                            title: 'deleteinstancequestion-text'
                                .i18n([distroLabel(widget.item)]),
                            body: 'deleteinstancebody-text'.i18n(),
                            submitText: 'delete-text'.i18n(),
                            submitInput: false,
                            submitStyle: ButtonStyle(
                              backgroundColor: ButtonState.all(Colors.red),
                              foregroundColor: ButtonState.all(Colors.white),
                            ),
                            onSubmit: (inputText) async {
                              await WSLApi().remove(widget.item);
                              Notify.message(
                                  'deletedinstance-text'.i18n([widget.item]));
                              // Force immediate UI refresh after deletion
                              if (GlobalVariable.refreshListCallback != null) {
                                (GlobalVariable.refreshListCallback as Function)();
                              }
                            });
                      }),
                ),
              ),
              Tooltip(
                message: 'settings-text'.i18n(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                      icon: const Icon(FluentIcons.settings, size: 16.0),
                      onPressed: () {
                        settingsDialog(widget.item);
                      }),
                ),
              ),
              Tooltip(
                message: 'Exportar distro',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                      icon: const Icon(FluentIcons.download, size: 16.0),
                      onPressed: () async {
                        // Mostrar el diálogo con un campo de texto y un botón para seleccionar archivo
                        final controller = TextEditingController();
                        controller.text = '$defaultPath\\Export-${widget.item}.tar';

                        // Crear un widget personalizado con campo de texto y botón para seleccionar ubicación
                        Widget exportLocationWidget = StatefulBuilder(
                          builder: (context, setState) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Seleccione la ubicación donde exportar la distro. Este proceso puede tardar varios minutos dependiendo del tamaño de la distribución.'),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextBox(
                                        controller: controller,
                                        placeholder: 'Ruta para exportar',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Button(
                                      child: const Text('Examinar...'),
                                      onPressed: () async {
                                        final result = await FilePicker.platform.saveFile(
                                          dialogTitle: 'Seleccione ubicación para exportar ${widget.item}',
                                          fileName: 'Export-${widget.item}.tar',
                                          type: FileType.any,
                                        );
                                        
                                        if (result != null && context.mounted) {
                                          setState(() {
                                            controller.text = result;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );

                        // Mostrar el diálogo con el widget personalizado
                        await showDialog(
                          context: GlobalVariable.infobox.currentContext!,
                          builder: (context) {
                            return ContentDialog(
                              title: Text('Exportar ${distroLabel(widget.item)}'),
                              content: exportLocationWidget,
                              actions: [
                                Button(
                                  child: const Text('Cancelar'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                FilledButton(
                                  child: const Text('Exportar'),
                                  onPressed: () async {
                                    final exportPath = controller.text;
                                    if (exportPath.isEmpty) return;
                                    
                                    Navigator.pop(context);
                                    
                                    // Verificar si la instancia está en ejecución
                                    bool instanceRunning = widget.running.contains(widget.item);
                                    
                                    // Si está en ejecución, detenerla primero
                                    if (instanceRunning) {
                                      Notify.message('Deteniendo ${widget.item} antes de exportar...', loading: true);
                                      await WSLApi().stop(widget.item);
                                      // Pequeña espera para asegurar que se detenga completamente
                                      await Future.delayed(const Duration(seconds: 2));
                                    }
                                    
                                    Notify.message('Exportando ${widget.item}...', loading: true);
                                    plausible.event(name: "wsl_exported");
                                    await WSLApi().export(widget.item, exportPath);
                                    Notify.message('${widget.item} exportado con éxito a $exportPath', loading: false);
                                    
                                    // Si estaba en ejecución, informar al usuario que fue detenida
                                    if (instanceRunning) {
                                      Notify.message('Nota: ${widget.item} ha sido detenida para realizar la exportación', loading: false, duration: const Duration(seconds: 5));
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
