import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

// --- CORE ---
import 'core/network/network_info.dart';
import 'core/services/secure_storage_service.dart';

// --- AUTH ---
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/login_user.dart';
import 'domain/usecases/register_user.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';

// --- DASHBOARD ---
import 'data/datasources/dashboard_remote_datasource.dart';
import 'data/repositories/dashboard_repository_impl.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'domain/usecases/get_dashboard_summary.dart';
import 'presentation/providers/dashboard_provider.dart';

// --- PROFILE ---
import 'data/datasources/profile_remote_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/usecases/profile_usecases.dart';
import 'presentation/providers/profile_provider.dart';

// --- FOOD ---
import 'data/datasources/food_remote_datasource.dart';
import 'data/repositories/food_repository_impl.dart';
import 'domain/repositories/food_repository.dart';
import 'domain/usecases/food_usecases.dart';
import 'presentation/providers/food_provider.dart';

// --- MEAL LOG ---
import 'data/datasources/meal_log_remote_datasource.dart';
import 'data/repositories/meal_log_repository_impl.dart';
import 'domain/repositories/meal_log_repository.dart';
import 'domain/usecases/create_meal_log.dart';
import 'presentation/providers/meal_log_provider.dart';
import 'domain/usecases/get_meal_logs.dart'; 
import 'domain/usecases/delete_meal_log.dart';

// --- WORKOUT ---
import 'data/datasources/workout_remote_datasource.dart';
import 'data/repositories/workout_repository_impl.dart';
import 'domain/repositories/workout_repository.dart';
import 'domain/usecases/workout_usecases.dart';
import 'presentation/providers/workout_provider.dart';

// --- SCREENS ---
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/intro/onboarding_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. EXTERNAL DEPENDENCIES
  final sharedPreferences = await SharedPreferences.getInstance();
  final httpClient = http.Client();
  final connectivity = Connectivity(); 
  const secureStorage = FlutterSecureStorage();

  // 2. KIỂM TRA ONBOARDING
  final bool seenOnboarding = sharedPreferences.getBool('seenOnboarding') ?? false;

  // 3. CORE SERVICES
  final storageService = SecureStorageService(secureStorage);
  final networkInfo = NetworkInfoImpl(connectivity);

  // === MANUAL DI (Dependency Injection) ===

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
  final dashboardProvider = DashboardProvider(
    getDashboardSummary: getDashboardSummary,
  );

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
    getUserProfile: getUserProfile,
    updateUserProfile: updateUserProfile,
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
    searchFood: searchFood,
    searchBarcode: searchBarcode,
  );

  // --- MEAL LOG ---
  final mealLogRemoteDatasource = MealLogRemoteDatasourceImpl(
    client: httpClient, storageService: storageService,
  );
  final mealLogRepository = MealLogRepositoryImpl(
    remoteDatasource: mealLogRemoteDatasource, networkInfo: networkInfo,
  );
  final createMealLog = CreateMealLog(mealLogRepository);
  
  // 2. (MỚI) KHỞI TẠO USECASE LẤY DANH SÁCH
  final getMealLogs = GetMealLogs(mealLogRepository);
  final deleteMealLog = DeleteMealLog(mealLogRepository);

  final mealLogProvider = MealLogProvider(
    createMealLog: createMealLog,
    getMealLogs: getMealLogs,
    deleteMealLog: deleteMealLog,
  );

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
    getExercises: getExercises,
    createWorkoutLog: createWorkoutLog,
  );

  // Tự động đăng nhập
  await authProvider.tryAutoLogin(); 
  
  runApp(
    MultiProvider(
      providers: [
        Provider<http.Client>(create: (_) => httpClient, dispose: (_, client) => client.close()),
        Provider<SharedPreferences>(create: (_) => sharedPreferences),
        Provider<NetworkInfo>(create: (_) => networkInfo),
        Provider<SecureStorageService>(create: (_) => storageService), 

        // AUTH Providers
        Provider<AuthRemoteDatasource>(create: (_) => authRemoteDatasource),
        Provider<AuthLocalDataSource>(create: (_) => authLocalDataSource),
        Provider<AuthRepository>(create: (_) => authRepository),
        Provider<LoginUser>(create: (_) => loginUser),
        Provider<RegisterUser>(create: (_) => registerUser),
        ChangeNotifierProvider.value(value: authProvider),

        // DASHBOARD Providers
        Provider<DashboardRemoteDatasource>(create: (_) => dashboardRemoteDatasource),
        Provider<DashboardRepository>(create: (_) => dashboardRepository),
        Provider<GetDashboardSummary>(create: (_) => getDashboardSummary),
        ChangeNotifierProvider.value(value: dashboardProvider),

        // PROFILE Providers
        Provider<ProfileRemoteDatasource>(create: (_) => profileRemoteDatasource),
        Provider<ProfileRepository>(create: (_) => profileRepository),
        Provider<GetUserProfile>(create: (_) => getUserProfile),
        Provider<UpdateUserProfile>(create: (_) => updateUserProfile),
        ChangeNotifierProvider.value(value: profileProvider),

        // FOOD Providers
        Provider<FoodRemoteDatasource>(create: (_) => foodRemoteDatasource),
        Provider<FoodRepository>(create: (_) => foodRepository),
        Provider<SearchFood>(create: (_) => searchFood),
        Provider<SearchBarcode>(create: (_) => searchBarcode),
        ChangeNotifierProvider.value(value: foodProvider),

        // MEAL LOG Providers
        Provider<MealLogRemoteDatasource>(create: (_) => mealLogRemoteDatasource),
        Provider<MealLogRepository>(create: (_) => mealLogRepository),
        Provider<CreateMealLog>(create: (_) => createMealLog),
        Provider<DeleteMealLog>(create: (_) => deleteMealLog),
        Provider<GetMealLogs>(create: (_) => getMealLogs),
        ChangeNotifierProvider.value(value: mealLogProvider),

        // WORKOUT Providers
        Provider<WorkoutRemoteDatasource>(create: (_) => workoutRemoteDatasource),
        Provider<WorkoutRepository>(create: (_) => workoutRepository),
        Provider<GetExercises>(create: (_) => getExercises),
        Provider<CreateWorkoutLog>(create: (_) => createWorkoutLog),
        ChangeNotifierProvider.value(value: workoutProvider),
      ],
      child: NutriMateApp(seenOnboarding: seenOnboarding),
    ),
  );
}

class NutriMateApp extends StatelessWidget {
  final bool seenOnboarding;
  
  const NutriMateApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriMate UI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA5),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isCheckingAuth) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF00BFA5),
                  ),
                ),
              ),
            );
          }
          
          if (auth.token != null) {
            return const MainScreen(); 
          }
          
          if (!seenOnboarding) {
            return const OnboardingScreen();
          }
          
          return const LoginScreen();
        },
      ),
      routes: {
        '/register': (context) => const RegisterScreen(), 
      }
    );
  }
}