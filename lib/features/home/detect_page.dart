import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import 'result_page.dart';

class DetectPage extends StatefulWidget {
  @override
  _DetectPageState createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> {
  File? _image;
  Uint8List? webImage;

  String selectedCrop = "rice";
  bool isLoading = false;

  final picker = ImagePicker();

  // =========================
  // CAMERA
  // =========================
  Future captureImage() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.camera);

      if (picked != null) {
        if (kIsWeb) {
          webImage = await picked.readAsBytes();
          _image = null;
        } else {
          _image = File(picked.path);
          webImage = null;
        }
        setState(() {});
      }
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  // =========================
  // GALLERY
  // =========================
  Future pickImage() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        if (kIsWeb) {
          webImage = await picked.readAsBytes();
          _image = null;
        } else {
          _image = File(picked.path);
          webImage = null;
        }
        setState(() {});
      }
    } catch (e) {
      print("Gallery Error: $e");
    }
  }

  // =========================
  // DETECT
  // =========================
  Future detect() async {
    if (_image == null && webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please select an image first")),
      );
      return;
    }

    setState(() => isLoading = true);

    Map<String, dynamic>? res;

    try {
      if (kIsWeb) {
        res = await ApiService.detectDiseaseWeb(webImage!, selectedCrop);
      } else {
        res = await ApiService.detectDisease(_image!, selectedCrop);
      }

      print("API RESPONSE: $res");
    } catch (e) {
      print("API ERROR: $e");

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Server error. Check backend")),
      );
      return;
    }

    if (!mounted) return;

    setState(() => isLoading = false);

    // =========================
    // 🔥 SMART RESPONSE HANDLING
    // =========================
    if (res != null && res["status"] == "success") {
      // ✅ normal success
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(data: res!),
        ),
      );
    } else {
      String label = res?["prediction"] ?? "";
      String message = res?["message"] ?? "";

      // 🔥 CASE 1: NOT A LEAF
      if (label == "unknown" && message.contains("leaf")) {
        showError("⚠️ Please upload a clear leaf image");
      }

      // 🔥 CASE 2: WRONG CROP
      else if (label == "unknown") {
        showError("⚠️ Selected crop does not match the image");
      }

      // 🔥 DEFAULT
      else {
        showError(message.isNotEmpty ? message : "Detection failed");
      }
    }
  }

  // =========================
  // ERROR UI (no UI change)
  // =========================
  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ $msg")),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detect Disease"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [

              Text(
                "Select your crop first",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),

              SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  cropCard("rice", "🌾", "Rice"),
                  cropCard("tea", "🍃", "Tea"),
                  cropCard("coconut", "🥥", "Coconut"),
                ],
              ),

              SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : captureImage,
                      icon: Icon(Icons.camera_alt),
                      label: Text("Camera"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : pickImage,
                      icon: Icon(Icons.upload),
                      label: Text("Upload"),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              Container(
                height: 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: (kIsWeb && webImage != null)
                        ? Image.memory(webImage!, fit: BoxFit.cover)
                        : (_image != null)
                            ? Image.file(_image!, fit: BoxFit.cover)
                            : Text(
                                "No image selected",
                                style: TextStyle(color: Colors.black54),
                              ),
                  ),
                ),
              ),

              SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : detect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Detect Disease",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // CROP CARD
  // =========================
  Widget cropCard(String crop, String emoji, String label) {
    bool selected = selectedCrop == crop;

    return GestureDetector(
      onTap: () => setState(() => selectedCrop = crop),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.green[50] : Colors.white,
          border: Border.all(
            color: selected ? Colors.green : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 20)),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12)),
            if (selected)
              Icon(Icons.check_circle, color: Colors.green, size: 16)
          ],
        ),
      ),
    );
  }
}