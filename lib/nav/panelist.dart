import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:localization/localization.dart';
import 'package:wsl2distromanager/components/constants.dart';
import 'package:wsl2distromanager/components/helpers.dart';
import 'package:wsl2distromanager/dialogs/create_dialog.dart';
import 'package:wsl2distromanager/dialogs/info_dialog.dart';
import 'package:wsl2distromanager/nav/linkaction.dart';
import 'package:wsl2distromanager/nav/router.dart';

final List<NavigationPaneItem> originalItems = [
  PaneItem(
    key: const Key('/'),
    icon: const Icon(FluentIcons.home),
    title: Text('homepage-text'.i18n()),
    body: const SizedBox.shrink(),
    onTap: () {
      // Mensaje de depuración extendido para verificar que se está pulsando el botón
      debugPrint('=======================================');
      debugPrint('BOTÓN HOME PULSADO! ${DateTime.now()}');
      debugPrint('Ruta actual: ${router.routerDelegate.currentConfiguration.uri.toString()}');
      debugPrint('=======================================');
      
      // Forzar actualización de la lista de distribuciones WSL
      // Resetear el snapshot fuerza a que el FutureBuilder recargue los datos
      GlobalVariable.initialSnapshot = null;
      
      // Navegación específica para Home
      router.go('/');
      
      // Asegurar que se actualice la interfaz si ya estamos en Home
      if (router.routerDelegate.currentConfiguration.uri.toString() == '/') {
        router.refresh();
      }
    },
  ),
  PaneItem(
    key: const Key('/quickactions'),
    icon: const Icon(FluentIcons.file_code),
    title: Text('managequickactions-text'.i18n()),
    body: const SizedBox.shrink(),
    onTap: () {
      // Mensaje de depuración para verificar que se está pulsando el botón
      debugPrint('=======================================');
      debugPrint('BOTÓN QUICK ACTIONS PULSADO! ${DateTime.now()}');
      debugPrint('Ruta actual: ${router.routerDelegate.currentConfiguration.uri.toString()}');
      debugPrint('=======================================');
      
      // Navegar directamente a Quick Actions con go() en lugar de pushNamed()
      router.go('/quickactions');
      
      // Si ya estamos en esa ruta, forzar un refresh para actualizar la vista
      if (router.routerDelegate.currentConfiguration.uri.toString() == '/quickactions') {
        router.refresh();
      }
    },
  ),
  PaneItem(
    key: const Key('/templates'),
    icon: const Icon(FluentIcons.file_template),
    title: Text('templates-text'.i18n()),
    body: const SizedBox.shrink(),
    onTap: () {
      // Mensaje de depuración para verificar que se está pulsando el botón
      debugPrint('=======================================');
      debugPrint('BOTÓN TEMPLATES PULSADO! ${DateTime.now()}');
      debugPrint('Ruta actual: ${router.routerDelegate.currentConfiguration.uri.toString()}');
      debugPrint('=======================================');
      
      // Navegar directamente a Templates con go() en lugar de pushNamed()
      router.go('/templates');
      
      // Si ya estamos en esa ruta, forzar un refresh para actualizar la vista
      if (router.routerDelegate.currentConfiguration.uri.toString() == '/templates') {
        router.refresh();
      }
    },
  ),
  PaneItem(
    key: const Key('/addinstance'),
    icon: const Icon(FluentIcons.add),
    title: Text('addinstance-text'.i18n()),
    body: const SizedBox.shrink(),
    onTap: () {
      createDialog();
    },
  ),
];
final List<NavigationPaneItem> footerItems = [
  LinkPaneItemAction(
    icon: const Icon(FluentIcons.heart),
    title: Text('sponsor-text'.i18n()),
    link: 'https://github.com/sponsors/bostrot',
    body: const SizedBox.shrink(),
  ),
  PaneItemSeparator(),
  PaneItem(
    key: const Key('/settings'),
    icon: const Icon(FluentIcons.settings),
    title: Text('settings-text'.i18n()),
    body: const SizedBox.shrink(),
    onTap: () {
      if (router.routerDelegate.currentConfiguration.uri.toString() !=
          '/settings') router.pushNamed('settings');
    },
  ),
  LinkPaneItemAction(
    icon: const Icon(FluentIcons.help),
    title: Text('documentation-text'.i18n()),
    link: 'https://github.com/bostrot/wsl2-distro-manager/wiki',
    body: const SizedBox.shrink(),
  ),
  PaneItem(
    key: const Key('/about'),
    icon: const Icon(FluentIcons.info),
    title: Text('about-text'.i18n()),
    body: const SizedBox.shrink(),
    onTap: () {
      infoDialog(prefs, currentVersion);
    },
  ),
];
