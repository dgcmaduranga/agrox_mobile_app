import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, String>> messages = [];
  bool isLoading = false;

  // =========================
  // SEND MESSAGE
  // =========================
  void sendMessage({String? editIndex}) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });

    controller.clear();
    scrollToBottom();

    final reply = await ApiService.askAI(text);

    setState(() {
      messages.add({"role": "bot", "text": reply ?? "Error occurred"});
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
      const SnackBar(content: Text("Copied")),
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),

      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: isDark ? Colors.white : Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF2E7D32),
                    child: Icon(Icons.smart_toy, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ask AgroX AI",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        "Smart farming assistant 🌱",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // ================= CHAT =================
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isUser = msg["role"] == "user";

                  return GestureDetector(
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.copy),
                                title: const Text("Copy"),
                                onTap: () {
                                  Navigator.pop(context);
                                  copyMessage(msg["text"] ?? "");
                                },
                              ),
                              if (isUser)
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text("Edit"),
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
                    child: Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFF2E7D32)
                              : (isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SelectableText(
                          msg["text"] ?? "",
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ================= LOADING =================
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text("Typing..."),
              ),

            // ================= INPUT =================
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: controller,
                        onSubmitted: (_) => sendMessage(),
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.black),
                        decoration: const InputDecoration(
                          hintText: "Type your question...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}