import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DetallePaquetePage extends StatefulWidget {
  final Map paquete;

  const DetallePaquetePage({super.key, required this.paquete});

  @override
  State<DetallePaquetePage> createState() => _DetallePaquetePageState();
}

class _DetallePaquetePageState extends State<DetallePaquetePage> {
  File? imagenFile;
  Uint8List? imagenBytes;
  Position? posicion;
  bool sending = false;

  bool get yaEntregado => widget.paquete["estado"] == "entregado";

  // ======================
  // TOMAR FOTO
  // ======================
  Future<void> tomarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (picked != null) {
      if (kIsWeb) {
        imagenBytes = await picked.readAsBytes();
      } else {
        imagenFile = File(picked.path);
      }
      setState(() {});
    }
  }

  // ======================
  // GPS
  // ======================
  Future<void> obtenerGPS() async {
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    posicion = await Geolocator.getCurrentPosition();
    setState(() {});
  }

  // ======================
  // ENVIAR ENTREGA
  // ======================
  Future<void> entregar() async {
    if ((imagenFile == null && imagenBytes == null) || posicion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Falta foto o ubicación")),
      );
      return;
    }

    setState(() => sending = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final agenteId = prefs.getInt("agente_id");

    final url = Uri.parse("http://localhost:8000/paquetes/entregar");

    final request = http.MultipartRequest("POST", url);
    request.headers["Authorization"] = "Bearer $token";

    request.fields["paquete_id"] = widget.paquete['id'].toString();
    request.fields["agente_id"] = agenteId.toString();
    request.fields["lat"] = posicion!.latitude.toString();
    request.fields["lng"] = posicion!.longitude.toString();
    request.fields["notas"] = "";

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "foto",
          imagenBytes!,
          filename: "foto_web.jpg",
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          "foto",
          imagenFile!.path,
        ),
      );
    }

    final resp = await request.send();
    setState(() => sending = false);

    if (resp.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al entregar: ${resp.statusCode}")),
      );
    }
  }

  // ======================
  // MOSTRAR IMAGEN
  // ======================
  Widget mostrarImagen() {
    if (kIsWeb) {
      return imagenBytes != null
          ? Image.memory(imagenBytes!, height: 200)
          : const Text("No hay imagen");
    }

    return imagenFile != null
        ? Image.file(imagenFile!, height: 200)
        : const Text("No hay imagen");
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paquete;

    return Scaffold(
      appBar: AppBar(title: Text("Paquete ${p['id']}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dirección: ${p['direccion_entrega']}"),
            Text("Descripción: ${p['descripcion']}"),
            Text("Estado: ${p['estado']}"),

            if (yaEntregado)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 25),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "✔ Este paquete ya fue entregado",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            if (!yaEntregado)
              ElevatedButton(
                onPressed: tomarFoto,
                child: const Text("Tomar / Subir Foto"),
              ),

            if (!yaEntregado) mostrarImagen(),

            const SizedBox(height: 20),

            if (!yaEntregado)
              ElevatedButton(
                onPressed: obtenerGPS,
                child: const Text("Obtener Ubicación"),
              ),

            if (posicion != null && !yaEntregado)
              Text("Lat: ${posicion!.latitude} - Lng: ${posicion!.longitude}"),

            const SizedBox(height: 30),

            if (!yaEntregado)
              sending
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: entregar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Paquete entregado",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
