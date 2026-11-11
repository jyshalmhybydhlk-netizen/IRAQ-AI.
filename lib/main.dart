import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const gold = Color(0xFFC5A059);
const teal = Color(0xFF00D6C9);
const bg = Color(0xFF080A0D);
const panel = Color(0xFF151B22);

void main() => runApp(const IraqAI());

class IraqAI extends StatelessWidget {
  const IraqAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IRAQ AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: teal,
          surface: panel,
        ),
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController input = TextEditingController();
  final ScrollController scroll = ScrollController();
  final List<Map<String, String>> msgs = [];

  String server = 'http://10.0.2.2:8000';
  String? cid;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('msgs');
    final loaded = <Map<String, String>>[];

    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map &&
                item['role'] != null &&
                item['content'] != null) {
              loaded.add({
                'role': item['role'].toString(),
                'content': item['content'].toString(),
              });
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      server = prefs.getString('server') ?? server;
      cid = prefs.getString('cid');
      msgs.addAll(loaded);
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server', server);
    await prefs.setString('msgs', jsonEncode(msgs));

    if (cid != null) {
      await prefs.setString('cid', cid!);
    } else {
      await prefs.remove('cid');
    }
  }

  Future<void> _settings() async {
    final controller = TextEditingController(text: server);

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إعدادات IRAQ AI'),
        content: TextField(
          controller: controller,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.5:8000',
            labelText: 'رابط الخادم',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null) return;

    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        !['http', 'https'].contains(uri.scheme)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رابط الخادم غير صالح')),
        );
      }
      return;
    }

    setState(() {
      server = value.replaceFirst(RegExp(r'/$'), '');
    });

    await _save();
  }

  Future<void> _newConversation() async {
    if (busy) return;

    setState(() {
      msgs.clear();
      cid = null;
    });

    await _save();
  }

  Future<void> _send() async {
    final message = input.text.trim();
    if (message.isEmpty || busy) return;

    setState(() {
      msgs.add({'role': 'user', 'content': message});
      busy = true;
    });

    input.clear();
    await _save();

    try {
      final response = await http
          .post(
            Uri.parse('$server/api/v1/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              if (cid != null) 'conversation_id': cid,
            }),
          )
          .timeout(const Duration(seconds: 190));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data is Map ? data['detail'] ?? 'HTTP ${response.statusCode}' : 'HTTP ${response.statusCode}',
        );
      }

      if (data is! Map ||
          data['answer'] == null ||
          data['conversation_id'] == null) {
        throw Exception('استجابة الخادم غير مكتملة');
      }

      if (!mounted) return;

      setState(() {
        cid = data['conversation_id'].toString();
        msgs.add({
          'role': 'assistant',
          'content': data['answer'].toString(),
        });
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        msgs.add({
          'role': 'assistant',
          'content': 'تعذر الاتصال بالخادم.\n\nالتفاصيل: $error',
        });
      });
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await _save();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'IRAQ AI - الذكاء الاصطناعي العراقي',
            style: TextStyle(color: gold, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: _settings,
              icon: const Icon(Icons.settings, color: teal),
              tooltip: 'الإعدادات',
            ),
            IconButton(
              onPressed: busy ? null : _newConversation,
              icon: const Icon(Icons.add_comment, color: gold),
              tooltip: 'محادثة جديدة',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: msgs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.psychology_alt,
                            color: teal,
                            size: 76,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'أهلاً بك في IRAQ AI',
                            style: TextStyle(
                              color: gold,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('اسألني أي سؤال باللغة العربية...'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        final message = msgs[index];
                        final isUser = message['role'] == 'user';

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 720),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFF123A39)
                                  : panel,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUser
                                    ? teal.withValues(alpha: 0.4)
                                    : gold.withValues(alpha: 0.25),
                              ),
                            ),
                            child: isUser
                                ? SelectableText(message['content'] ?? '')
                                : MarkdownBody(
                                    data: message['content'] ?? '',
                                    selectable: true,
                                  ),
                          ),
                        );
                      },
                    ),
            ),
            if (busy)
              const LinearProgressIndicator(color: teal),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: panel,
                          hintText: 'اكتب سؤالك هنا...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: busy ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }
}
