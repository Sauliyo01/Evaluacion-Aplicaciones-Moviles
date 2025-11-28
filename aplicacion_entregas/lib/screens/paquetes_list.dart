import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ListPaquetesPage extends StatefulWidget {
  const ListPaquetesPage({super.key});

  @override
  State<ListPaquetesPage> createState() => _ListPaquetesPageState();
}

class _ListPaquetesPageState extends State<ListPaquetesPage> {
  List paquetes = [];
  bool loading = true;

  Future<void> cargarPaquetes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final agenteId = prefs.getInt("agente_id");

    final url = Uri.parse("http://localhost:8000/paquetes/$agenteId");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      paquetes = jsonDecode(response.body);
    }

    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    cargarPaquetes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paquetes Asignados")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: paquetes.length,
              itemBuilder: (context, i) {
                final p = paquetes[i];

                return Card(
                  child: ListTile(
                    title: Text("ID: ${p['id']}"),

                    // ✔️ Corrección: campo correcto + manejo de NULL
                    subtitle: Text(p['direccion_entrega'] ?? "Sin dirección"),

                    trailing: ElevatedButton(
                      child: const Text("Ver Detalles"),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          "/detalle",
                          arguments: p,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
