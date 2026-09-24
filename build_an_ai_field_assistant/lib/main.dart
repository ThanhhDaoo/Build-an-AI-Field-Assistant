import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection_container.dart';
import 'features/inspection/presentation/controllers/inspection_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Service Locator (GetIt)
  await initInjection();

  // Obtain controller from DI container
  final inspectionController = sl<InspectionController>();

  runApp(FieldAiAssistantApp(controller: inspectionController));
}
