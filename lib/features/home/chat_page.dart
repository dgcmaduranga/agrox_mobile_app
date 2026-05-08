import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

// ===============================
// APP THEME COLORS
// ===============================
const Color kDarkGreen = Color(0xFF0B5D1E);
const Color kMainGreen = Color(0xFF1B7F35);
const Color kLightGreen = Color(0xFFEAF8E7);

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, String>> messages = [];
  bool isLoading = false;

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // =========================
  // SEND MESSAGE
  // =========================
  void sendMessage({String? editIndex}) async {
    final text = controller.text.trim();
    if (text.isEmpty || isLoading) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });

    controller.clear();
    scrollToBottom();

    final reply = await ApiService.askAI(text);

    if (!mounted) return;

    setState(() {
      messages.add({
        "role": "bot",
        "text": reply ?? "Sorry, AgroX AI could not respond right now.",
      });
      isLoading = false;
    });

    scrollToBottom();
  }

  // =========================
  // COPY MESSAGE
  // =========================
  void copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Copied"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // =========================
  // EDIT MESSAGE
  // =========================
  void editMessage(int index) {
    controller.text = messages[index]["text"] ?? "";

    setState(() {
      messages.removeRange(index, messages.length);
    });
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // =========================
  // SHOW MESSAGE OPTIONS
  // =========================
  void _showMessageOptions({
    required bool isDark,
    required bool isUser,
    required String text,
    required int index,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                _bottomSheetTile(
                  icon: Icons.copy_rounded,
                  title: "Copy",
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    copyMessage(text);
                  },
                ),
                if (isUser)
                  _bottomSheetTile(
                    icon: Icons.edit_rounded,
                    title: "Edit",
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      editMessage(index);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bottomSheetTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? kDarkGreen.withOpacity(0.18) : kLightGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: kDarkGreen,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color scaffoldBg =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F8F5);

    final Color cardBg = isDark ? const Color(0xFF161B22) : Colors.white;

    final Color inputBg =
        isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F2);

    final Color mainText = isDark ? Colors.white : const Color(0xFF102014);

    final Color subText = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _premiumHeader(
              context: context,
              isDark: isDark,
              mainText: mainText,
              subText: subText,
            ),

            Expanded(
              child: messages.isEmpty
                  ? _emptyChatView(
                      isDark: isDark,
                      mainText: mainText,
                      subText: subText,
                    )
                  : ListView.builder(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isUser = msg["role"] == "user";
                        final text = msg["text"] ?? "";

                        return _messageBubble(
                          context: context,
                          isDark: isDark,
                          isUser: isUser,
                          text: text,
                          index: index,
                          cardBg: cardBg,
                        );
                      },
                    ),
            ),

            if (isLoading)
              _typingIndicator(
                isDark: isDark,
                cardBg: cardBg,
                subText: subText,
              ),

            _inputBar(
              isDark: isDark,
              inputBg: inputBg,
              mainText: mainText,
              subText: subText,
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // PREMIUM HEADER
  // =========================
  Widget _premiumHeader({
    required BuildContext context,
    required bool isDark,
    required Color mainText,
    required Color subText,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
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
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Ask AgroX AI",
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
                Text(
                  "Agriculture assistant 🌱",
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

  // =========================
  // EMPTY CHAT VIEW - AGRICULTURE ONLY
  // =========================
  Widget _emptyChatView({
    required bool isDark,
    required Color mainText,
    required Color subText,
  }) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: isDark
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          kLightGreen,
                        ],
                      ),
                color: isDark ? const Color(0xFF102A1A) : null,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kDarkGreen.withOpacity(0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark
                        ? kDarkGreen.withOpacity(0.22)
                        : Colors.white.withOpacity(0.95),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kDarkGreen.withOpacity(0.10),
                    ),
                  ),
                  child: const Icon(
                    Icons.agriculture_rounded,
                    color: kDarkGreen,
                    size: 34,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "How can I help your farming today?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mainText,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Ask agriculture-related questions about crop diseases, pests, fertilizer, soil, irrigation, weather risks, crop care, or harvesting.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subText,
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 26),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : kDarkGreen.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.16 : 0.045),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF102A1A) : kLightGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: kDarkGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Only agriculture-field questions are supported here.",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // MESSAGE BUBBLE
  // =========================
  Widget _messageBubble({
    required BuildContext context,
    required bool isDark,
    required bool isUser,
    required String text,
    required int index,
    required Color cardBg,
  }) {
    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(
          isDark: isDark,
          isUser: isUser,
          text: text,
          index: index,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF102A1A) : kLightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: kDarkGreen,
                  size: 19,
                ),
              ),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF064E1A),
                            Color(0xFF0B5D1E),
                            Color(0xFF1B7F35),
                          ],
                        )
                      : null,
                  color: isUser ? null : cardBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 5),
                    bottomRight: Radius.circular(isUser ? 5 : 18),
                  ),
                  border: isUser
                      ? null
                      : Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04),
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? kDarkGreen.withOpacity(0.16)
                          : Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SelectableText(
                  text,
                  style: TextStyle(
                    color: isUser
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                    fontSize: 14.2,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            if (isUser) ...[
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: isDark ? Colors.white70 : kDarkGreen,
                  size: 19,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================
  // TYPING INDICATOR
  // =========================
  Widget _typingIndicator({
    required bool isDark,
    required Color cardBg,
    required Color subText,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF102A1A) : kLightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: kDarkGreen,
              size: 19,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: isDark ? Colors.green.shade300 : kDarkGreen,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "AgroX AI is typing...",
                  style: TextStyle(
                    color: subText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // INPUT BAR
  // =========================
  Widget _inputBar({
    required bool isDark,
    required Color inputBg,
    required Color mainText,
    required Color subText,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F8F5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 50,
                maxHeight: 118,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : kDarkGreen.withOpacity(0.08),
                ),
              ),
              child: TextField(
                controller: controller,
                onSubmitted: (_) => sendMessage(),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                style: TextStyle(
                  color: mainText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: "Ask an agriculture question...",
                  hintStyle: TextStyle(
                    color: subText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 9),

          GestureDetector(
            onTap: isLoading ? null : sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isLoading
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF064E1A),
                          Color(0xFF0B5D1E),
                          Color(0xFF1B7F35),
                        ],
                      ),
                color: isLoading ? kDarkGreen.withOpacity(0.45) : null,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kDarkGreen.withOpacity(0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}