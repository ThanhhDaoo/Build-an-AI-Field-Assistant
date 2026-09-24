import 'package:get_it/get_it.dart';
import '../../features/inspection/data/datasources/inspection_local_ds.dart';
import '../../features/inspection/data/datasources/inspection_remote_ds.dart';
import '../../features/inspection/data/repositories/inspection_repository_impl.dart';
import '../../features/inspection/domain/repositories/i_inspection_repository.dart';
import '../../features/inspection/presentation/controllers/inspection_controller.dart';
import '../network/api_client.dart';
import '../services/audio_player_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/connectivity_service.dart';
import '../services/speech_to_text_service.dart';

/// Service Locator instance (GetIt)
final sl = GetIt.instance;

/// Initialize all system dependencies, native hardware services & repositories
Future<void> initInjection() async {
  // 1. Hardware & Native Services
  sl.registerLazySingleton<AudioRecorderService>(() => AudioRecorderService());
  sl.registerLazySingleton<AudioPlayerService>(() => AudioPlayerService());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<SpeechToTextService>(() => SpeechToTextService());

  // 2. Networking
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // 3. Data Sources
  sl.registerLazySingleton<IInspectionLocalDataSource>(
    () => InspectionLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<IInspectionRemoteDataSource>(
    () => InspectionRemoteDataSourceImpl(apiClient: sl()),
  );

  // 4. Repository (Online/Offline Coordinator)
  sl.registerLazySingleton<IInspectionRepository>(
    () => InspectionRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      connectivityService: sl(),
    ),
  );

  // 5. State Management / Presentation Controllers
  sl.registerFactory<InspectionController>(
    () => InspectionController(
      repository: sl(),
      audioRecorderService: sl(),
      connectivityService: sl(),
      speechToTextService: sl(),
    ),
  );
}
