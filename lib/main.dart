import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Import Core
import 'core/network/network_info.dart';
import 'core/services/secure_storage_service.dart';
import 'core/error/failures.dart'; 
// Import Data
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/datasources/dashboard_remote_datasource.dart';
import 'data/repositories/dashboard_repository_impl.dart';
import 'data/datasources/profile_remote_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
// Import Domain
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/login_user.dart';
import 'domain/usecases/register_user.dart';
import 'domain/entities/user.dart'; 
import 'domain/usecases/get_dashboard_summary.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/usecases/profile_usecases.dart';
// Import Presentation
import 'presentation/screens/auth/login_screen.dart'; 
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/profile_provider.dart';

import 'core/error/exceptions.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // === EXTERNAL DEPENDENCIES ===
  final sharedPreferences = await SharedPreferences.getInstance();
  final httpClient = http.Client();
  final connectivity = Connectivity(); 
  const secureStorage = FlutterSecureStorage();

  // Core Services
  final storageService = SecureStorageService(secureStorage);

  // === MANUAL DEPENDENCY INJECTION (DI) ===
  // Core Services 
  final networkInfo = NetworkInfoImpl(connectivity);

  // 2. Data Sources
  final authRemoteDatasource = AuthRemoteDatasourceImpl(httpClient);
  final authLocalDataSource = AuthLocalDataSourceImpl(sharedPreferences);

  // Repository
  final authRepository = AuthRepositoryImpl(
    remoteDatasource: authRemoteDatasource, 
    localDataSource: authLocalDataSource, 
    networkInfo: networkInfo, 
  );

  // Use Cases
  final loginUser = LoginUser(authRepository);
  final registerUser = RegisterUser(authRepository);
  
  //  Auth Provider 
  final authProvider = AuthProvider(
    loginUser: loginUser,
    registerUser: registerUser,
    storageService: storageService,
  );
  
  // --- DASHBOARD ---
  final dashboardRemoteDatasource = DashboardRemoteDatasourceImpl(
    client: httpClient,
    storageService: storageService,
  );

  final dashboardRepository = DashboardRepositoryImpl(
    remoteDatasource: dashboardRemoteDatasource,
    networkInfo: networkInfo,
  );

  final getDashboardSummary = GetDashboardSummary(dashboardRepository);
  final dashboardProvider = DashboardProvider(
    getDashboardSummary: getDashboardSummary,
  );

  // --- PROFILE ---
  final profileRemoteDatasource = ProfileRemoteDatasourceImpl(
    client: httpClient,
    storageService: storageService,
  );
  final profileRepository = ProfileRepositoryImpl(
    remoteDatasource: profileRemoteDatasource,
    networkInfo: networkInfo,
  );
  final getUserProfile = GetUserProfile(profileRepository);
  final updateUserProfile = UpdateUserProfile(profileRepository);
  final profileProvider = ProfileProvider(
    getUserProfile: getUserProfile,
    updateUserProfile: updateUserProfile,
  );

  await authProvider.tryAutoLogin(); 
  
  runApp(
    MultiProvider(
      providers: [
        // EXTERNAL DEPENDENCIES
        Provider<http.Client>(create: (_) => httpClient, dispose: (_, client) => client.close()),
        Provider<SharedPreferences>(create: (_) => sharedPreferences),
        
        // CORE SERVICES 
        Provider<NetworkInfo>(create: (_) => networkInfo),
        Provider<SecureStorageService>(create: (_) => storageService), 

        // DATA SOURCES
        Provider<AuthRemoteDatasource>(create: (_) => authRemoteDatasource),
        Provider<AuthLocalDataSource>(create: (_) => authLocalDataSource),

        // REPOSITORY
        Provider<AuthRepository>(create: (_) => authRepository),

        // USE CASES
        Provider<LoginUser>(create: (_) => loginUser),
        Provider<RegisterUser>(create: (_) => registerUser),
        
        // AUTH PROVIDER
        ChangeNotifierProvider.value(value: authProvider),

        // DASHBOARD DEPENDENCIES
        Provider<DashboardRemoteDatasource>(create: (_) => dashboardRemoteDatasource),
        Provider<DashboardRepository>(create: (_) => dashboardRepository),
        Provider<GetDashboardSummary>(create: (_) => getDashboardSummary),
        ChangeNotifierProvider.value(value: dashboardProvider),

        // PROFILE DEPENDENCIES
        Provider<ProfileRemoteDatasource>(create: (_) => profileRemoteDatasource),
        Provider<ProfileRepository>(create: (_) => profileRepository),
        Provider<GetUserProfile>(create: (_) => getUserProfile),
        Provider<UpdateUserProfile>(create: (_) => updateUserProfile),
        ChangeNotifierProvider.value(value: profileProvider),
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
          // LOADING when checking token
          if (auth.isCheckingAuth) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          if (auth.token != null) {
            // TODO: Thay thế bằng màn hình Trang Chủ (HomeScreen)
            return const DashboardScreen();
          }
          
          // INITIAL/ERROR
          return const LoginScreen();
        },
      ),
      routes: {
        '/register': (context) => const Text('RegisterScreen'),
        '/home': (context) => const Text('HomeScreen'),
      }
    );
  }
}
