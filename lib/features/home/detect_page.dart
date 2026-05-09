import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/history_service.dart';
import '../../services/language_provider.dart';
import '../../widgests/translated_text.dart';
import 'result_page.dart';

class DetectPage extends StatefulWidget {
  const DetectPage({super.key});

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> {
  File? _image;
  Uint8List? webImage;

  String selectedCrop = "tea";
  bool isLoading = false;

  final ImagePicker picker = ImagePicker();

  static const Color kDarkGreen = Color(0xFF0B5D1E);
  static const Color kMainGreen = Color(0xFF1B7F35);
  static const Color kLightGreen = Color(0xFFEAF8E7);

  Future<void> captureImage() async {
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (picked == null) return;

      if (kIsWeb) {
        webImage = await picked.readAsBytes();
        _image = null;
      } else {
        _image = File(picked.path);
        webImage = null;
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
      if (!mounted) return;
      showError("Camera error. Please try again");
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      if (kIsWeb) {
        webImage = await picked.readAsBytes();
        _image = null;
      } else {
        _image = File(picked.path);
        webImage = null;
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint("Gallery Error: $e");
      if (!mounted) return;
      showError("Gallery error. Please try again");
    }
  }

  Future<void> detect() async {
    if (isLoading) return;

    if (_image == null && webImage == null) {
      showWarning("Please select an image first");
      return;
    }

    setState(() => isLoading = true);

    Map<String, dynamic>? res;

    try {
      if (kIsWeb) {
        if (webImage == null) {
          throw Exception("Web image is empty");
        }

        res = await ApiService.detectDiseaseWeb(
          webImage!,
          selectedCrop,
        );
      } else {
        if (_image == null) {
          throw Exception("Image file is empty");
        }

        res = await ApiService.detectDisease(
          _image!,
          selectedCrop,
        );
      }

      debugPrint("SELECTED CROP: $selectedCrop");
      debugPrint("API RESPONSE: $res");
    } catch (e) {
      debugPrint("API ERROR: $e");

      if (!mounted) return;
      setState(() => isLoading = false);

      showError("Connection failed. Please try again later");
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = false);

    if (res == null) {
      showError("Something went wrong. Please try again");
      return;
    }

    final String status = res["status"]?.toString().toLowerCase().trim() ?? "";

    if (status == "success") {
      res["crop"] = res["crop"]?.toString().isNotEmpty == true
          ? res["crop"].toString()
          : selectedCrop;

      final double accuracy = res["accuracy"] is num
          ? (res["accuracy"] as num).toDouble()
          : double.tryParse(res["accuracy"]?.toString() ?? "0") ?? 0.0;

      try {
        await HistoryService.saveDetection(
          diseaseName: res["disease"]?.toString() ?? "Unknown Disease",
          crop: res["crop"]?.toString() ?? selectedCrop,
          riskLevel: res["risk"]?.toString() ?? "Low",
          accuracy: accuracy,
          dateTime: DateTime.now(),
        );
      } catch (e) {
        debugPrint("History Save Error: $e");
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(data: res!),
        ),
      );

      return;
    }

    handleFailedResponse(res);
  }

  void handleFailedResponse(Map<String, dynamic> res) {
    final String prediction =
        res["prediction"]?.toString().toLowerCase().trim() ?? "";

    final String reason =
        res["reason"]?.toString().toLowerCase().trim() ?? "";

    final String message = res["message"]?.toString().trim() ?? "";
    final String lowerMsg = message.toLowerCase();

    debugPrint("FAILED PREDICTION: $prediction");
    debugPrint("FAILED REASON: $reason");
    debugPrint("FAILED MESSAGE: $message");

    if (prediction == "unknown" ||
        reason == "wrong_crop_or_invalid_leaf" ||
        lowerMsg.contains("selected crop does not match") ||
        lowerMsg.contains("does not match") ||
        lowerMsg.contains("invalid image") ||
        lowerMsg.contains("wrong crop")) {
      showError("Selected crop does not match the image");
      return;
    }

    if (reason == "low_confidence" ||
        reason == "uncertain_prediction" ||
        lowerMsg.contains("clear leaf") ||
        lowerMsg.contains("clear") ||
        lowerMsg.contains("low confidence")) {
      showError("Please upload a clear ${_cropName(selectedCrop)} image");
      return;
    }

    if (reason == "model_not_loaded" ||
        reason == "labels_not_loaded" ||
        reason == "label_index_mismatch" ||
        lowerMsg.contains("model") ||
        lowerMsg.contains("label")) {
      showError(
        "Detection service is temporarily unavailable. Please try again later",
      );
      return;
    }

    if (reason == "prediction_exception" ||
        lowerMsg.contains("prediction failed") ||
        lowerMsg.contains("failed")) {
      showError("Detection could not be completed. Please try again");
      return;
    }

    if (message.isNotEmpty) {
      showError(message);
      return;
    }

    showError("Detection could not identify this image");
  }

  void showError(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText("❌ $msg"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void showWarning(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText("⚠️ $msg"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _cropName(String crop) {
    switch (crop.toLowerCase()) {
      case "tea":
        return "tea leaf";
      case "coconut":
        return "coconut leaf";
      case "rice":
        return "rice leaf";
      default:
        return "leaf";
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageProvider>(context);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color scaffoldBg =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F8F5);

    final Color cardBg = isDark ? const Color(0xFF161B22) : Colors.white;

    final Color softGreenBg =
        isDark ? const Color(0xFF102A1A) : const Color(0xFFEAF8E7);

    final Color mainText = isDark ? Colors.white : const Color(0xFF102014);

    final Color subText = isDark ? Colors.white60 : Colors.grey.shade600;

    final Color borderColor =
        isDark ? Colors.green.shade700 : Colors.green.shade300;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                children: [
                  _premiumTopHeader(context),

                  const SizedBox(height: 14),

                  Center(
                    child: TranslatedText(
                      "Select your leaf type first",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: mainText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Center(
                    child: TranslatedText(
                      "Choose the crop leaf before capturing or uploading",
                      style: TextStyle(
                        fontSize: 12,
                        color: subText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      cropCard(
                        crop: "tea",
                        emoji: "🌱",
                        label: "Tea Leaf",
                        isDark: isDark,
                      ),
                      cropCard(
                        crop: "coconut",
                        emoji: "🌿",
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

                  const SizedBox(height: 14),

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

                  const SizedBox(height: 14),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: borderColor,
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.24)
                                : kDarkGreen.withOpacity(0.07),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: softGreenBg,
                            gradient: isDark
                                ? null
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFEAF8E7),
                                      Color(0xFFF8FFF9),
                                    ],
                                  ),
                          ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 62,
                                            height: 62,
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
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Colors.black.withOpacity(
                                                    isDark ? 0.18 : 0.05,
                                                  ),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: isDark
                                                  ? Colors.green.shade300
                                                  : kDarkGreen,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          TranslatedText(
                                            "No image selected",
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade800,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                            ),
                                            child: Center(
                                              child: TranslatedText(
                                                "Use a clear, non-blurry, natural leaf image with the full leaf clearly visible",
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white38
                                                      : Colors.grey.shade500,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : detect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDarkGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: kDarkGreen.withOpacity(0.75),
                        elevation: 8,
                        shadowColor: kDarkGreen.withOpacity(0.34),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: isLoading
                            ? Row(
                                key: const ValueKey("loading"),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  TranslatedText(
                                    "Detecting...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const TranslatedText(
                                key: ValueKey("normal"),
                                "Detect Disease",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (isLoading)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.10),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF161B22).withOpacity(0.96)
                              : Colors.white.withOpacity(0.97),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : kDarkGreen.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 36,
                              width: 36,
                              child: CircularProgressIndicator(
                                color: kDarkGreen,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TranslatedText(
                              "Analyzing leaf image...",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TranslatedText(
                              "Please wait a moment",
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _premiumTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E1A),
            Color(0xFF0B5D1E),
            Color(0xFF1B7F35),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: kDarkGreen.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                TranslatedText(
                  "Detect Disease",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                TranslatedText(
                  "AI crop disease scanner 🌱",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.green.shade700 : Colors.green.shade300,
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.22)
                    : kDarkGreen.withOpacity(0.07),
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
                color: kDarkGreen,
                size: 21,
              ),
              const SizedBox(width: 9),
              TranslatedText(
                label,
                style: TextStyle(
                  color: isDark ? Colors.green.shade300 : kDarkGreen,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cropCard({
    required String crop,
    required String emoji,
    required String label,
    required bool isDark,
  }) {
    final bool selected = selectedCrop == crop;

    return GestureDetector(
      onTap: isLoading ? null : () => setState(() => selectedCrop = crop),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        width: 97,
        height: 108,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF102A1A) : kLightGreen)
              : (isDark ? const Color(0xFF161B22) : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? kDarkGreen
                : (isDark ? Colors.green.shade800 : Colors.green.shade200),
            width: selected ? 2 : 1.15,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? kDarkGreen.withOpacity(isDark ? 0.26 : 0.18)
                  : Colors.black.withOpacity(isDark ? 0.20 : 0.04),
              blurRadius: selected ? 15 : 9,
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
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? kDarkGreen.withOpacity(0.12)
                          : kLightGreen.withOpacity(isDark ? 0.12 : 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? kDarkGreen.withOpacity(0.25)
                            : Colors.green.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: TextStyle(
                          fontSize: crop == "tea" ? 29 : 27,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TranslatedText(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? kDarkGreen
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  Icons.check_circle,
                  color: kDarkGreen,
                  size: 19,
                ),
              ),
          ],
        ),
      ),
    );
  }
}