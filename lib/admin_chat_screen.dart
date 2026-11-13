import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

// ==========================================
// Admin Inbox (List of users with messages)
// ==========================================
class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return;

      final res = await http.get(
        Uri.parse('https://ubuntu-4gb-hel1-2.tail7f4de4.ts.net:10000/api/admin/chat/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          _users = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text(AppTranslations.t('chat.inbox'), style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _users.isEmpty
              ? Center(child: Text(AppTranslations.t('chat.no_messages'), style: TextStyle(color: textColor)))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    final uname = u['username'] ?? 'Unknown';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accent.withOpacity(0.2),
                        child: Text(uname.isNotEmpty ? uname[0].toUpperCase() : '?', style: TextStyle(color: accent)),
                      ),
                      title: Text(uname, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text('ID: ${u['id']}', style: TextStyle(color: textColor.withOpacity(0.7))),
                      trailing: Icon(Icons.chevron_right, color: accent),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => AdminChatDetailScreen(userId: u['id'], username: uname)),
                        ).then((_) => _fetchUsers());
                      },
                    );
                  },
                ),
    );
  }
}

// ==========================================
// Admin Chat Detail (Chat screen)
// ==========================================
class AdminChatDetailScreen extends StatefulWidget {
  final int userId;
  final String username;
  const AdminChatDetailScreen({super.key, required this.userId, required this.username});

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
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
        Uri.parse('https://ubuntu-4gb-hel1-2.tail7f4de4.ts.net:10000/api/admin/chat/history/${widget.userId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() {
            _messages = data;
            _isLoading = false;
          });
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
        Uri.parse('https://ubuntu-4gb-hel1-2.tail7f4de4.ts.net:10000/api/admin/chat/reply'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.userId, 'message': text}),
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
        title: Text(widget.username, style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accent))
                : _messages.isEmpty
                    ? Center(child: Text(AppTranslations.t('chat.no_messages'), style: TextStyle(color: textColor)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isAdmin = msg['sender_id'] == 0;
                          return Align(
                            alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isAdmin ? accent : (isDark ? const Color(0xFF202d42) : const Color(0xFFe2e8f0)),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isAdmin ? 12 : 0),
                                  bottomRight: Radius.circular(isAdmin ? 0 : 12),
                                ),
                              ),
                              child: Text(msg['message'], style: TextStyle(color: isAdmin ? Colors.black : textColor, fontSize: 14)),
                            ),
                          );
                        },
                      ),
          ),
          Container(
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
                  icon: _isSending
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                      : Icon(Icons.send, color: accent),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
