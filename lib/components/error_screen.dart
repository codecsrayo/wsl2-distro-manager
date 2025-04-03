import 'package:fluent_ui/fluent_ui.dart';

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  final String? stackTrace;
  final VoidCallback onClose;

  const ErrorScreen({
    Key? key,
    required this.errorMessage,
    this.stackTrace,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      home: NavigationView(
        content: ScaffoldPage(
          header: const PageHeader(
            title: Text("Error Crítico"),
          ),
          content: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Se ha producido un error crítico en la aplicación:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.lightest,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (stackTrace != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Detalles técnicos (para reportar el error):",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      height: 200,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[20],
                        border: Border.all(color: Colors.grey[130]), // Eliminado ! innecesario
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          // Forzamos la conversión a String no nulo ya que sabemos que no es null
                          stackTrace as String,
                          style: const TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    "Posibles soluciones:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "1. Reiniciar la aplicación\n"
                    "2. Eliminar manualmente los archivos de preferencias en: %LOCALAPPDATA%\\flutter_tools.wsl2distromanager\n"
                    "3. Reinstalar la aplicación",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Button(
                      style: ButtonStyle(
                        backgroundColor: ButtonState.all(Colors.red),
                        foregroundColor: ButtonState.all(Colors.white),
                      ),
                      onPressed: onClose,
                      child: const Text("Cerrar aplicación"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
