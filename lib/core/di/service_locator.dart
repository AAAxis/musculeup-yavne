import 'package:get_it/get_it.dart';
import 'package:muscleup/data/services/firebase_auth_service.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/services/storage_service.dart';
import 'package:muscleup/data/services/signature_migration_service.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Services
  getIt.registerLazySingleton<FirestoreService>(() => FirestoreService());
  getIt.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<SignatureMigrationService>(() => SignatureMigrationService());

  // BLoCs
  getIt.registerFactory<AuthBloc>(() => AuthBloc(authService: getIt()));
}

