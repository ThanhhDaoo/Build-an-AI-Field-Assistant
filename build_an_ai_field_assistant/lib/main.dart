import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/audio_recorder_service.dart';
import 'core/services/connectivity_service.dart';
import 'features/inspection/data/datasources/inspection_local_ds.dart';
import 'features/inspection/data/datasources/inspection_remote_ds.dart';
import 'features/inspection/data/repositories/inspection_repository_impl.dart';
import 'features/inspection/presentation/controllers/inspection_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize core services
  final connectivityService = ConnectivityService();
  final audioRecorderService = AudioRecorderService();

  // 2. Initialize Data Sources
  final localDataSource = InspectionLocalDataSourceImpl();
  final remoteDataSource = InspectionRemoteDataSourceImpl();

  // 3. Initialize Repository (coordinating Online vs Offline)
  final repository = InspectionRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    connectivityService: connectivityService,
  );

  // 4. Initialize Presentation Controller
  final inspectionController = InspectionController(
    repository: repository,
    audioRecorderService: audioRecorderService,
    connectivityService: connectivityService,
  );

  runApp(FieldAiAssistantApp(controller: inspectionController));
}
