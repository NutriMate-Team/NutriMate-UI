import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core
import 'core/network/network_info.dart';
import 'core/services/secure_storage_service.dart';

// Auth
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/usecases/login_user.dart';
import 'domain/usecases/register_user.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';

// Dashboard
import 'data/datasources/dashboard_remote_datasource.dart';
import 'data/repositories/dashboard_repository_impl.dart';
import 'domain/usecases/get_dashboard_summary.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'presentation/providers/dashboard_provider.dart';

// Profile
import 'data/datasources/profile_remote_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/usecases/profile_usecases.dart';
import 'domain/repositories/profile_repository.dart';
import 'presentation/providers/profile_provider.dart';

// Food
import 'data/datasources/food_remote_datasource.dart';
import 'data/repositories/food_repository_impl.dart';
import 'domain/usecases/food_usecases.dart';
import 'domain/repositories/food_repository.dart';
import 'presentation/providers/food_provider.dart';

// Meal Log
import 'data/datasources/meal_log_remote_datasource.dart';
import 'data/repositories/meal_log_repository_impl.dart';
import 'domain/usecases/create_meal_log.dart';
import 'domain/repositories/meal_log_repository.dart';
import 'presentation/providers/meal_log_provider.dart';

// Workout
import 'data/datasources/workout_remote_datasource.dart';
import 'data/repositories/workout_repository_impl.dart';
import 'domain/usecases/workout_usecases.dart';
import 'domain/repositories/workout_repository.dart';
import 'presentation/providers/workout_provider.dart';

import 'presentation/screens/main_screen.dart'; 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final sharedPreferences = await SharedPreferences.getInstance();
  final httpClient = http.Client();
  final connectivity = Connectivity(); 
  const secureStorage = FlutterSecureStorage();

  final storageService = SecureStorageService(secureStorage);
  final networkInfo = NetworkInfoImpl(connectivity);

  // --- AUTH ---
  final authRemoteDatasource = AuthRemoteDatasourceImpl(httpClient);
  final authLocalDataSource = AuthLocalDataSourceImpl(sharedPreferences);
  final authRepository = AuthRepositoryImpl(
    remoteDatasource: authRemoteDatasource, 
    localDataSource: authLocalDataSource, 
    networkInfo: networkInfo, 
  );
  final loginUser = LoginUser(authRepository);
  final registerUser = RegisterUser(authRepository);
  final authProvider = AuthProvider(
    loginUser: loginUser,
    registerUser: registerUser,
    storageService: storageService,
  );
  
  // --- DASHBOARD ---
  final dashboardRemoteDatasource = DashboardRemoteDatasourceImpl(
    client: httpClient, storageService: storageService,
  );
  final dashboardRepository = DashboardRepositoryImpl(
    remoteDatasource: dashboardRemoteDatasource, networkInfo: networkInfo,
  );
  final getDashboardSummary = GetDashboardSummary(dashboardRepository);
  final dashboardProvider = DashboardProvider(getDashboardSummary: getDashboardSummary);

  // --- PROFILE ---
  final profileRemoteDatasource = ProfileRemoteDatasourceImpl(
    client: httpClient, storageService: storageService,
  );
  final profileRepository = ProfileRepositoryImpl(
    remoteDatasource: profileRemoteDatasource, networkInfo: networkInfo,
  );
  final getUserProfile = GetUserProfile(profileRepository);
  final updateUserProfile = UpdateUserProfile(profileRepository);
  final profileProvider = ProfileProvider(
    getUserProfile: getUserProfile, updateUserProfile: updateUserProfile,
  );

  // --- FOOD ---
  final foodRemoteDatasource = FoodRemoteDatasourceImpl(
    client: httpClient, storageService: storageService,
  );
  final foodRepository = FoodRepositoryImpl(
    remoteDatasource: foodRemoteDatasource, networkInfo: networkInfo,
  );
  final searchFood = SearchFood(foodRepository);
  final searchBarcode = SearchBarcode(foodRepository);
  final foodProvider = FoodProvider(
    searchFood: searchFood, searchBarcode: searchBarcode,
  );

  // --- MEAL LOG ---
  final mealLogRemoteDatasource = MealLogRemoteDatasourceImpl(
    client: httpClient, storageService: storageService,
  );
  final mealLogRepository = MealLogRepositoryImpl(
    remoteDatasource: mealLogRemoteDatasource, networkInfo: networkInfo,
  );
  final createMealLog = CreateMealLog(mealLogRepository);
  final mealLogProvider = MealLogProvider(createMealLog: createMealLog);

  // --- WORKOUT ---
  final workoutRemoteDatasource = WorkoutRemoteDatasourceImpl(
    client: httpClient, storageService: storageService,
  );
  final workoutRepository = WorkoutRepositoryImpl(
    remoteDatasource: workoutRemoteDatasource, networkInfo: networkInfo,
  );
  final getExercises = GetExercises(workoutRepository);
  final createWorkoutLog = CreateWorkoutLog(workoutRepository);
  final workoutProvider = WorkoutProvider(
    getExercises: getExercises, createWorkoutLog: createWorkoutLog,
  );

  await authProvider.tryAutoLogin(); 
  
  runApp(
    MultiProvider(
      providers: [
        Provider<http.Client>(create: (_) => httpClient, dispose: (_, client) => client.close()),
        Provider<SharedPreferences>(create: (_) => sharedPreferences),
        Provider<NetworkInfo>(create: (_) => networkInfo),
        Provider<SecureStorageService>(create: (_) => storageService), 

        // Auth
        Provider<AuthRemoteDatasource>(create: (_) => authRemoteDatasource),
        Provider<AuthLocalDataSource>(create: (_) => authLocalDataSource),
        Provider<AuthRepository>(create: (_) => authRepository),
        Provider<LoginUser>(create: (_) => loginUser),
        Provider<RegisterUser>(create: (_) => registerUser),
        ChangeNotifierProvider.value(value: authProvider),

        // Dashboard
        Provider<DashboardRemoteDatasource>(create: (_) => dashboardRemoteDatasource),
        Provider<DashboardRepository>(create: (_) => dashboardRepository),
        Provider<GetDashboardSummary>(create: (_) => getDashboardSummary),
        ChangeNotifierProvider.value(value: dashboardProvider),

        // Profile
        Provider<ProfileRemoteDatasource>(create: (_) => profileRemoteDatasource),
        Provider<ProfileRepository>(create: (_) => profileRepository),
        Provider<GetUserProfile>(create: (_) => getUserProfile),
        Provider<UpdateUserProfile>(create: (_) => updateUserProfile),
        ChangeNotifierProvider.value(value: profileProvider),

        // Food
        Provider<FoodRemoteDatasource>(create: (_) => foodRemoteDatasource),
        Provider<FoodRepository>(create: (_) => foodRepository),
        Provider<SearchFood>(create: (_) => searchFood),
        Provider<SearchBarcode>(create: (_) => searchBarcode),
        ChangeNotifierProvider.value(value: foodProvider),

        // Meal Log
        Provider<MealLogRemoteDatasource>(create: (_) => mealLogRemoteDatasource),
        Provider<MealLogRepository>(create: (_) => mealLogRepository),
        Provider<CreateMealLog>(create: (_) => createMealLog),
        ChangeNotifierProvider.value(value: mealLogProvider),

        // Workout
        Provider<WorkoutRemoteDatasource>(create: (_) => workoutRemoteDatasource),
        Provider<WorkoutRepository>(create: (_) => workoutRepository),
        Provider<GetExercises>(create: (_) => getExercises),
        Provider<CreateWorkoutLog>(create: (_) => createWorkoutLog),
        ChangeNotifierProvider.value(value: workoutProvider),
      ],
      child: const NutriMateApp(),
    ),
  );
}

class NutriMateApp extends StatelessWidget {
  const NutriMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriMate UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isCheckingAuth) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          if (auth.token != null) {
            // 2. SỬA: Chuyển đến MainScreen (có thanh điều hướng)
            return const MainScreen(); 
          }
          
          return const LoginScreen();
        },
      ),
      routes: {
        '/register': (context) => const Text('RegisterScreen'), 
      }
    );
  }
}