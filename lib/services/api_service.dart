import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// 🔥 ADD
import 'app_config.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  // =========================
  // MOBILE
  // =========================
  static Future<Map<String, dynamic>?> detectDisease(
      File image, String crop) async {
    try {
      var uri = Uri.parse("$baseUrl/detect");

      var request = http.MultipartRequest("POST", uri);

      request.files.add(
        await http.MultipartFile.fromPath("file", image.path),
      );

      request.fields["crop"] = crop;

      // 🔥 ADD LANGUAGE
      request.fields["lang"] = AppConfig.lang;

      var response = await request.send();

      var resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);

      if (data["status"] == "success") {
        return data;
      } else {
        print("API ERROR: ${data["message"]}");
        return null;
      }
    } catch (e) {
      print("ERROR: $e");
      return null;
    }
  }

  // =========================
  // WEB
  // =========================
  static Future<Map<String, dynamic>?> detectDiseaseWeb(
      Uint8List imageBytes, String crop) async {
    try {
      var uri = Uri.parse("$baseUrl/detect");

      var request = http.MultipartRequest("POST", uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          imageBytes,
          filename: "image.jpg",
        ),
      );

      request.fields["crop"] = crop;

      // 🔥 ADD LANGUAGE
      request.fields["lang"] = AppConfig.lang;

      var response = await request.send();

      var resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);

      if (data["status"] == "success") {
        return data;
      } else {
        print("API ERROR: ${data["message"]}");
        return null;
      }
    } catch (e) {
      print("WEB ERROR: $e");
      return null;
    }
  }

  // =========================
  // CHATBOT (UPDATED 🔥)
  // =========================
  static Future<String> askAI(String question) async {
    try {
      var uri = Uri.parse("$baseUrl/chat");

      var response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "question": question,

          // 🔥 ADD LANGUAGE
          "lang": AppConfig.lang,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["response"] != null) {
        return data["response"];
      } else {
        return "No response from AI";
      }
    } catch (e) {
      print("CHAT ERROR: $e");
      return "Error connecting to AI";
    }
  }
}