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
    File image,
    String crop,
  ) async {
    try {
      final uri = Uri.parse("$baseUrl/detect");

      final request = http.MultipartRequest("POST", uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          image.path,
        ),
      );

      request.fields["crop"] = crop;

      // 🔥 ADD LANGUAGE
      request.fields["lang"] = AppConfig.lang;

      final response = await request.send();

      final resBody = await response.stream.bytesToString();

      print("DETECT STATUS: ${response.statusCode}");
      print("DETECT BODY: $resBody");

      if (resBody.isEmpty) {
        return {
          "status": "failed",
          "prediction": "unknown",
          "reason": "empty_response",
          "message": "Detection could not be completed. Please try again",
        };
      }

      final decoded = jsonDecode(resBody);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        "status": "failed",
        "prediction": "unknown",
        "reason": "invalid_response",
        "message": "Detection could not be completed. Please try again",
      };
    } catch (e) {
      print("ERROR: $e");

      return {
        "status": "failed",
        "prediction": "unknown",
        "reason": "connection_error",
        "message": "Connection failed. Please try again later",
      };
    }
  }

  // =========================
  // WEB
  // =========================
  static Future<Map<String, dynamic>?> detectDiseaseWeb(
    Uint8List imageBytes,
    String crop,
  ) async {
    try {
      final uri = Uri.parse("$baseUrl/detect");

      final request = http.MultipartRequest("POST", uri);

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

      final response = await request.send();

      final resBody = await response.stream.bytesToString();

      print("WEB DETECT STATUS: ${response.statusCode}");
      print("WEB DETECT BODY: $resBody");

      if (resBody.isEmpty) {
        return {
          "status": "failed",
          "prediction": "unknown",
          "reason": "empty_response",
          "message": "Detection could not be completed. Please try again",
        };
      }

      final decoded = jsonDecode(resBody);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        "status": "failed",
        "prediction": "unknown",
        "reason": "invalid_response",
        "message": "Detection could not be completed. Please try again",
      };
    } catch (e) {
      print("WEB ERROR: $e");

      return {
        "status": "failed",
        "prediction": "unknown",
        "reason": "connection_error",
        "message": "Connection failed. Please try again later",
      };
    }
  }

  // =========================
  // CHATBOT
  // =========================
  static Future<String> askAI(String question) async {
    try {
      final uri = Uri.parse("$baseUrl/chat");

      final response = await http.post(
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

      if (response.body.isEmpty) {
        return "No response from AI";
      }

      final data = jsonDecode(response.body);

      if (data["response"] != null) {
        return data["response"];
      } else {
        return "No response from AI";
      }
    } catch (e) {
      print("CHAT ERROR: $e");
      return "Unable to connect. Please try again later";
    }
  }
}