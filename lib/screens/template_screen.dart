import 'package:fluent_ui/fluent_ui.dart';
import 'package:localization/localization.dart';
import 'package:wsl2distromanager/api/templates.dart';
import 'package:wsl2distromanager/api/wsl.dart'; // Para WSLApi
import 'package:wsl2distromanager/components/helpers.dart';
import 'dart:io';

/// Template Screen
class TemplatePage extends StatefulWidget {
  const TemplatePage({super.key});

  @override
  State<TemplatePage> createState() => _TemplatePageState();
}

/// Template Screen State
class _TemplatePageState extends State<TemplatePage> {
  List<String> _templates = [];
  bool _isLoading = true;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    // Cargar automáticamente los templates incluyendo los del disco
    _loadTemplates(true);
  }

  /// Carga los templates y actualiza el estado
  /// [autoDetect] si es true, escanea automáticamente el disco buscando templates no registrados
  Future<void> _loadTemplates([bool autoDetect = false]) async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Cargando templates...';
    });
    
    try {
      // Intentar cargar los templates
      final templates = Templates().getTemplates();
      debugPrint('Templates cargados: ${templates.length}');
      
      // Mostrar información de depuración sobre los templates
      for (var template in templates) {
        var size = Templates().getTemplateSize(template);
        debugPrint('Template: $template, Tamaño: $size');
      }
      
      // Actualizar el estado con los templates cargados
      setState(() {
        _templates = templates;
        _isLoading = false;
        _debugInfo = 'Templates cargados: ${templates.length}';
      });
      
      // Si autoDetect está activado y no hay templates (o hay muy pocos), escanear disco
      if (autoDetect && templates.isEmpty) {
        await _scanForTemplates();
      }
    } catch (e) {
      debugPrint('Error cargando templates: $e');
      setState(() {
        _isLoading = false;
        _debugInfo = 'Error: $e';
      });
    }
  }
  
  /// Busca archivos de template en el directorio y los añade a SharedPreferences
  Future<void> _scanForTemplates() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Buscando templates en disco...';
    });
    
    try {
      // Obtener la ruta del directorio de templates
      final templatePath = Templates().getTemplatePath().path;
      debugPrint('Buscando templates en: $templatePath');
      
      // Verificar si el directorio existe
      final directory = Directory(templatePath);
      if (!directory.existsSync()) {
        setState(() {
          _isLoading = false;
          _debugInfo = 'El directorio de templates no existe: $templatePath';
        });
        return;
      }
      
      // Buscar archivos .ext4 en el directorio
      final files = directory.listSync()
          .where((file) => file.path.toLowerCase().endsWith('.ext4'))
          .map((file) => file.path)
          .toList();
      
      debugPrint('Archivos .ext4 encontrados: ${files.length}');
      
      // Obtener la lista actual de templates
      List<String> currentTemplates = Templates().getTemplates();
      
      // Añadir los archivos encontrados a la lista de templates
      int newTemplatesCount = 0;
      for (var filePath in files) {
        // Obtener el nombre del archivo sin la extensión
        final fileName = filePath.split('\\').last.replaceAll('.ext4', '');
        debugPrint('Template encontrado: $fileName, Ruta: $filePath');
        
        // Añadir a la lista si no existe ya
        if (!currentTemplates.contains(fileName)) {
          currentTemplates.add(fileName);
          newTemplatesCount++;
        }
      }
      
      // Guardar la lista actualizada de templates
      if (newTemplatesCount > 0) {
        prefs.setStringList('templates', currentTemplates);
        debugPrint('Añadidos $newTemplatesCount nuevos templates');
      }
      
      // Cargar la lista actualizada
      _loadTemplates();
      
      setState(() {
        _debugInfo = 'Búsqueda completa. Añadidos $newTemplatesCount nuevos templates.';
      });
    } catch (e) {
      debugPrint('Error escaneando templates: $e');
      setState(() {
        _isLoading = false;
        _debugInfo = 'Error escaneando: $e';
      });
    }
  }
  
  /// Muestra un diálogo para crear un template a partir de una distribución existente
  Future<void> _showCreateTemplateDialog() async {
    try {
      // Obtener la lista de distribuciones WSL instaladas
      final wslApi = WSLApi();
      final instances = await wslApi.list(false);
      final distros = instances.all;
      
      if (distros.isEmpty) {
        setState(() {
          _debugInfo = 'No hay distribuciones WSL instaladas para crear un template';
        });
        return;
      }
      
      // Mostrar diálogo para seleccionar una distribución
      showDialog(
        context: context,
        builder: (context) {
          String? selectedDistro = distros.first;
          
          return ContentDialog(
            title: Text('createtemplate-text'.i18n()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('selectdistrofortemplate-text'.i18n()),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ComboBox<String>(
                    value: selectedDistro,
                    items: distros.map((distro) => ComboBoxItem<String>(
                      value: distro,
                      child: Text(distro),
                    )).toList(),
                    onChanged: (value) {
                      selectedDistro = value;
                    },
                  ),
                ),
              ],
            ),
            actions: [
              Button(
                child: Text('cancel-text'.i18n()),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FilledButton(
                child: Text('createtemplate-text'.i18n()),
                onPressed: () async {
                  Navigator.pop(context);
                  if (selectedDistro != null) {
                    setState(() {
                      _isLoading = true;
                      _debugInfo = 'Creando template a partir de $selectedDistro...';
                    });
                    
                    // Crear el template
                    await Templates().saveTemplate(selectedDistro!);
                    
                    // Recargar la lista de templates
                    _loadTemplates();
                  }
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error al mostrar diálogo de creación de template: $e');
      setState(() {
        _debugInfo = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar un indicador de carga si está cargando
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ProgressRing(),
            const SizedBox(height: 16),
            Text('loadingtemplates-text'.i18n()),
          ],
        ),
      );
    }
    
    // Mostrar un mensaje si no hay templates
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('notemplates-text'.i18n(), style: FluentTheme.of(context).typography.subtitle),
            const SizedBox(height: 16),
            // Botón para recargar los templates
            Button(
              child: Text('reload-text'.i18n()),
              onPressed: () {
                _loadTemplates();
              },
            ),
            const SizedBox(height: 8),
            // Botón para escanear el directorio de templates
            Button(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FluentIcons.search),
                  const SizedBox(width: 8),
                  Text('searchtemplates-text'.i18n()),
                ],
              ),
              onPressed: () {
                _scanForTemplates();
              },
            ),
            const SizedBox(height: 8),
            // Botón para crear un nuevo template
            Button(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FluentIcons.add),
                  const SizedBox(width: 8),
                  Text('createtemplate-text'.i18n()),
                ],
              ),
              onPressed: () {
                _showCreateTemplateDialog();
              },
            ),
            const SizedBox(height: 8),
            // Mostrar información de depuración
            Text(_debugInfo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }
    
    // Encabezado y lista scrollable
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con formato # Templates (número)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              '${'templates-text'.i18n()} ${_templates.length}',
              style: FluentTheme.of(context).typography.title,
            ),
          ),
          
          // Información de depuración
          Text(_debugInfo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          
          // Lista scrollable de templates
          Expanded(
            child: ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                var name = _templates[index];
                var templatePath = Templates().getTemplateFilePath(name);
                bool fileExists = File(templatePath).existsSync();
                var size = Templates().getTemplateSize(name);
                
                // Mostrar mensaje de depuración
                debugPrint('Template $name: Existe: $fileExists, Ruta: $templatePath, Tamaño: $size');
                
                // Si el archivo no existe o tiene tamaño 0, mostrar un elemento especial
                if (size == '0 GB' || !fileExists) {
                  return Card(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: FluentTheme.of(context).typography.bodyStrong),
                        const SizedBox(height: 4),
                        Text('Archivo no encontrado o corrupto', 
                            style: const TextStyle(color: Colors.warningPrimaryColor)),
                        const SizedBox(height: 8),
                        Button(
                          child: Text('removefromlist-text'.i18n()),
                          onPressed: () async {
                            await Templates().deleteTemplate(name);
                            _loadTemplates(); // Recargar la lista
                          },
                        ),
                      ],
                    ),
                  );
                }
                
                // Si el archivo existe, mostrar el elemento normal expandible
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Expander(
                    header: Text('$name ($size)'),
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Button(
                          child: Row(
                            children: [
                              const Icon(FluentIcons.add),
                              const SizedBox(width: 10.0),
                              Text('createnewinstance-text'.i18n()),
                            ],
                          ),
                          onPressed: () {
                            // Implementación directa usando el contexto actual
                            final TextEditingController inputController = TextEditingController();
                            
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return ContentDialog(
                                  title: Text('${'copy-text'.i18n()} "$name"'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('copyinstance-text'.i18n([distroLabel(name)])),
                                      const SizedBox(height: 10),
                                      TextBox(
                                        controller: inputController,
                                        placeholder: 'Nombre de la nueva instancia...',
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    Button(
                                      child: Text('cancel-text'.i18n()),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                    FilledButton(
                                      child: Text('copy-text'.i18n()),
                                      onPressed: () async {
                                        final String inputText = inputController.text.trim();
                                        if (inputText.isNotEmpty) {
                                          // Guardamos una referencia al contexto antes de la operación asíncrona
                                          final BuildContext currentContext = dialogContext;
                                          await Templates().useTemplate(name, inputText);
                                          // Verificamos si el contexto sigue siendo válido antes de usarlo
                                          if (currentContext.mounted) {
                                            Navigator.of(currentContext).pop();
                                          }
                                        } else {
                                          // Si no hay texto, simplemente cerramos el diálogo
                                          if (dialogContext.mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.delete),
                          onPressed: () {
                            // Usar contexto directo en lugar de GlobalVariable.infobox
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return ContentDialog(
                                  title: Text('deleteinstancequestion-text'.i18n([distroLabel(name)])),
                                  content: Text('deleteinstancebody-text'.i18n()),
                                  actions: [
                                    Button(
                                      child: Text('cancel-text'.i18n()),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                    Button(
                                      child: Text('delete-text'.i18n()),
                                      style: ButtonStyle(
                                        backgroundColor: ButtonState.all(Colors.red),
                                        foregroundColor: ButtonState.all(Colors.white),
                                      ),
                                      onPressed: () async {
                                        await Templates().deleteTemplate(name);
                                        _loadTemplates(); // Recargar después de eliminar
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
