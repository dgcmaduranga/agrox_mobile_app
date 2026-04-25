import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import 'result_page.dart';

class DetectPage extends StatefulWidget {
  const DetectPage({super.key});

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> {
  File? _image;
  Uint8List? webImage;

  // ✅ Default selected crop is Tea
  String selectedCrop = "tea";

  bool isLoading = false;

  final picker = ImagePicker();

  // =========================
  // CAMERA
  // =========================
  Future captureImage() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

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
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

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
        const SnackBar(
          content: Text("⚠️ Please select an image first"),
          behavior: SnackBarBehavior.floating,
        ),
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
        const SnackBar(
          content: Text("❌ Server error. Check backend"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() => isLoading = false);

    if (res != null && res["status"] == "success") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(data: res!),
        ),
      );
    } else {
      String label = res?["prediction"] ?? "";
      String message = res?["message"] ?? "";

      if (label == "unknown" && message.contains("leaf")) {
        showError("⚠️ Please upload a clear leaf image");
      } else if (label == "unknown") {
        showError("⚠️ Selected crop does not match the image");
      } else {
        showError(message.isNotEmpty ? message : "Detection failed");
      }
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ $msg"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color scaffoldBg =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F8F5);

    final Color cardBg =
        isDark ? const Color(0xFF161B22) : Colors.white;

    final Color softGreenBg =
        isDark ? const Color(0xFF102A1A) : const Color(0xFFEAF8E7);

    final Color mainText =
        isDark ? Colors.white : Colors.black87;

    final Color subText =
        isDark ? Colors.white60 : Colors.grey.shade600;

    final Color borderColor =
        isDark ? Colors.green.shade700 : Colors.green.shade300;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: mainText),
        title: Text(
          "Detect Disease",
          style: TextStyle(
            color: mainText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Select your leaf type first",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: mainText,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Center(
                  child: Text(
                    "Choose the crop leaf before capturing or uploading",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: subText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    cropCard(
                      crop: "tea",
                      emoji: "🍃",
                      label: "Tea Leaf",
                      isDark: isDark,
                    ),
                    cropCard(
                      crop: "coconut",
                      emoji: "🥥",
                      label: "Coconut Leaf",
                      isDark: isDark,
                    ),
                    cropCard(
                      crop: "rice",
                      emoji: "🌾",
                      label: "Rice Leaf",
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: Icons.camera_alt_rounded,
                        label: "Camera",
                        onTap: isLoading ? null : captureImage,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.file_upload_outlined,
                        label: "Upload",
                        onTap: isLoading ? null : pickImage,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  height: 245,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: borderColor,
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.25)
                            : Colors.green.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: softGreenBg,
                      child: Center(
                        child: (kIsWeb && webImage != null)
                            ? InteractiveViewer(
                                minScale: 0.8,
                                maxScale: 4,
                                child: Image.memory(
                                  webImage!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : (_image != null)
                                ? InteractiveViewer(
                                    minScale: 0.8,
                                    maxScale: 4,
                                    child: Image.file(
                                      _image!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1F2937)
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.green.shade700
                                                : Colors.green.shade200,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.image_outlined,
                                          color: Colors.green.shade500,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "No image selected",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.grey.shade700,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Capture or upload a clear leaf image",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : detect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC4A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          isDark ? Colors.green.shade900 : Colors.green.shade200,
                      elevation: 6,
                      shadowColor: Colors.green.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Text(
                            "Detect Disease",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // ACTION BUTTON
  // =========================
  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.green.shade700 : Colors.green.shade300,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.22)
                    : Colors.green.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.green.shade500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.green.shade300 : Colors.green.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
  Widget cropCard({
    required String crop,
    required String emoji,
    required String label,
    required bool isDark,
  }) {
    final bool selected = selectedCrop == crop;

    return GestureDetector(
      onTap: () => setState(() => selectedCrop = crop),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 96,
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF102A1A) : const Color(0xFFEAF8E7))
              : (isDark ? const Color(0xFF161B22) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.green
                : (isDark ? Colors.green.shade800 : Colors.green.shade200),
            width: selected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? Colors.green.withOpacity(isDark ? 0.22 : 0.18)
                  : Colors.black.withOpacity(isDark ? 0.20 : 0.04),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 25),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? Colors.green.shade400
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            if (selected)
              Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade500,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}