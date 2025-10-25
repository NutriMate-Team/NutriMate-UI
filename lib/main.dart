import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import './core/network/network_info.dart';
import './data/datasources/auth_local_datasource.dart';
import './presentation/screens/auth/login_screen.dart'; 
import './presentation/providers/auth_provider.dart';
import './domain/usecases/login_user.dart';
import './domain/usecases/register_user.dart';
import './domain/repositories/auth_repository.dart';
import './data/repositories/auth_repository_impl.dart';
import './data/datasources/auth_remote_datasource.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  final httpClient = http.Client();
  final connectivity = Connectivity(); 

  runApp(
    MultiProvider(
      providers: [
        Provider<http.Client>(
          create: (_) => httpClient,
          dispose: (_, client) => client.close(), 
        ),
        Provider<SharedPreferences>(
          create: (_) => sharedPreferences,
        ),
        Provider<Connectivity>(
          create: (_) => connectivity,
        ),
        
        // 2. Cung cấp NetworkInfo
        Provider<NetworkInfo>(
          create: (context) => NetworkInfoImpl(
            context.read<Connectivity>(), 
          ),
        ),


        Provider<AuthRemoteDatasource>(
          create: (context) => AuthRemoteDatasourceImpl(
            context.read<http.Client>(), 
          ),
        ),
        Provider<AuthLocalDataSource>(
          create: (context) => AuthLocalDataSourceImpl(
            context.read<SharedPreferences>(), 
          ),
        ),

        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            remoteDatasource: context.read<AuthRemoteDatasource>(), 
            localDataSource: context.read<AuthLocalDataSource>(), 
            networkInfo: context.read<NetworkInfo>(), 
          ),
        ),

        // 5. Cung cấp các Use Cases
        Provider<LoginUser>(
          create: (context) => LoginUser(
            context.read<AuthRepository>(),
          ),
        ),
        Provider<RegisterUser>(
          create: (context) => RegisterUser(
            context.read<AuthRepository>(),
          ),
        ),
        
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            loginUser: context.read<LoginUser>(),
            registerUser: context.read<RegisterUser>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          // TODO: Bạn nên thêm một hàm 'tryAutoLogin' trong AuthProvider
          // để kiểm tra token từ localDataSource lúc khởi động
          
          if (auth.token != null) {
            return Scaffold(body: Center(child: Text('Đã đăng nhập!')));
          }
          return const LoginScreen();
        },
      ),
    );
  }
}