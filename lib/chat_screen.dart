import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class ChatScreen extends StatefulWidget {
  final String? userId;
  const ChatScreen({super.key, this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _resolvedUserId = 0;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _resolvedUserId = int.tryParse(widget.userId ?? '') ?? 0;
    _fetchMessages();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchMessages(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return;

      final res = await http.get(
        Uri.parse('https://ubuntu-4gb-hel1-2.tail7f4de4.ts.net:10000/api/chat/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() { _messages = data; _isLoading = false; });
          _scrollToBottom();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final res = await http.post(
        Uri.parse('https://ubuntu-4gb-hel1-2.tail7f4de4.ts.net:10000/api/chat/send'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );
      if (res.statusCode == 200) {
        _msgCtrl.clear();
        await _fetchMessages();
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF080d14) : const Color(0xFFf8fafc);
    final cardBg = isDark ? const Color(0xFF141b28) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0f172a);
    final accent = isDark ? const Color(0xFF00d9ff) : const Color(0xFF0891b2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 1,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: accent), onPressed: () => Navigator.pop(context)),
        title: Text(AppTranslations.t('chat.title'), style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accent))
                : _messages.isEmpty
                    ? Center(child: Text(AppTranslations.t('chat.no_messages'), style: TextStyle(color: textColor.withOpacity(0.5))))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMine = msg['sender_id'] == _resolvedUserId;
                          return _buildBubble(msg['message'], isMine, isDark, accent, textColor);
                        },
                      ),
          ),
          _buildInput(cardBg, textColor, accent),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isMine, bool isDark, Color accent, Color textColor) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? accent : (isDark ? const Color(0xFF202d42) : const Color(0xFFe2e8f0)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12), topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 0), bottomRight: Radius.circular(isMine ? 0 : 12),
          ),
        ),
        child: Text(text, style: TextStyle(color: isMine ? Colors.black : textColor, fontSize: 14)),
      ),
    );
  }

  Widget _buildInput(Color cardBg, Color textColor, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: cardBg, border: Border(top: BorderSide(color: textColor.withOpacity(0.1)))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: AppTranslations.t('chat.type_message'),
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: _isSending ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accent)) : Icon(Icons.send, color: accent),
            onPressed: _isSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
