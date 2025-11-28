import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login.dart';
import 'screens/paquetes_list.dart';
import 'screens/detalles_paquete.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paquexpress',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        future: _checkLogin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          return snapshot.data! ? const ListPaquetesPage() : const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/paquetes': (context) => const ListPaquetesPage(),
      },
      // Ruta dinámica (requiere argumentos)
      onGenerateRoute: (settings) {
        if (settings.name == '/detalle') {
          final paquete = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => DetallePaquetePage(paquete: paquete),
          );
        }
        return null;
      },
    );
  }
}
