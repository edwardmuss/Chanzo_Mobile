import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'chat_drawer.dart';

class ChatPageScreen extends StatefulWidget {
  @override
  _ChatPageScreenState createState() => _ChatPageScreenState();
}

class _ChatPageScreenState extends State<ChatPageScreen> {
  List<Map<String, dynamic>> messages = [];
  TextEditingController _controller = TextEditingController();
  bool isThinking = false;
  bool showWelcome = true;
  String currentSessionId = '';
  StreamSubscription? _subscription;
  late ScrollController _scrollController;

  List<Map<String, dynamic>> sessions = [];
  TextEditingController _searchController = TextEditingController();
  int currentPage = 1;
  bool hasMore = true;
  Map<int, bool> expandedMessages = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    fetchSessions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void fetchSessions({bool reset = false}) async {
    if (reset) {
      setState(() {
        sessions.clear();
        currentPage = 1;
        hasMore = true;
      });
    }

    if (!hasMore) return;

    final search = _searchController.text.trim();

    final uri = Uri.parse(
            "https://ai.chanzo.co.ke/users/${authController.userId.toString()}/sessions?limit=10")
        .replace(queryParameters: {
      'page': currentPage.toString(),
      if (search.isNotEmpty) 'q': search,
    });

    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();

    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);

      final newSessions = List<Map<String, dynamic>>.from(data['data'] ?? []);

      setState(() {
        sessions.addAll(newSessions);
        hasMore = newSessions.length >= 10; // Assuming page size = 10
        currentPage++;
      });
    }
  }

  void loadMessagesFromSession(String sessionId) async {
    setState(() {
      showWelcome = false;
    });
    final uri =
        Uri.parse("https://ai.chanzo.co.ke/sessions/$sessionId/history");
    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(responseBody);

      if (decoded is List) {
        final now = DateTime.now();
        final List<Map<String, dynamic>> timestampedMessages = [];

        for (int i = 0; i < decoded.length; i++) {
          final msg = Map<String, dynamic>.from(decoded[i]);
          msg['timestamp'] = now
              .subtract(Duration(minutes: decoded.length - i))
              .toIso8601String();
          if (msg['type'] == 'ai') {
            msg['isMarkdown'] = true;
          }
          timestampedMessages.add(msg);
        }

        setState(() {
          currentSessionId = sessionId;
          messages = timestampedMessages;
        });

        _scrollToBottom();
      } else {
        print("Unexpected data format: $decoded");
      }
    } else {
      print("Failed to load messages. Status code: ${response.statusCode}");
    }
  }

  void sendMessage(String input) async {
    if (input.trim().isEmpty) return;

    setState(() {
      messages.add({
        "type": "human",
        "content": input,
        "timestamp": DateTime.now().toIso8601String(),
      });
      isThinking = true;
      showWelcome = false;
    });
    _scrollToBottom();
    _controller.clear();

    if (currentSessionId.isEmpty) {
      currentSessionId =
          '${DateTime.now().millisecondsSinceEpoch}_${authController.userId}';
    }

    if (messages.length == 1) {
      messages.insert(0, {
        "type": "ai",
        "content": "This is the beginning of your conversation with Chanzo AI.",
        "isIntro": true,
        "timestamp": DateTime.now().toIso8601String(),
      });
    }

    final request = {
      "user_input": input,
      "user_id": authController.userId.toString(),
      "thread_id": currentSessionId
    };

    try {
      final client = HttpClient();
      final uri = Uri.parse("https://ai.chanzo.co.ke/chat");
      final requestBody = utf8.encode(jsonEncode(request));

      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('Accept', 'text/event-stream');
      req.add(requestBody);

      final res = await req.close();
      String buffer = "";
      String streamedText = "";
      bool isFirstChunk = true;

      final subscription = res.transform(utf8.decoder).listen(
        (chunk) {
          buffer += chunk;
          final lines = buffer.split("\n");
          buffer = lines.removeLast();

          for (final line in lines) {
            if (line.startsWith("data:")) {
              try {
                final jsonLine =
                    jsonDecode(line.replaceFirst("data:", "").trim());
                if (jsonLine["node"] == "agent" && jsonLine["data"] != null) {
                  streamedText += jsonLine["data"];
                  setState(() {
                    if (isFirstChunk) {
                      messages.add({
                        "type": "ai",
                        "content": streamedText,
                        "isMarkdown": true,
                        "timestamp": DateTime.now().toIso8601String(),
                        // Ensure consistent format
                      });
                      isFirstChunk = false;
                    } else {
                      messages[messages.length - 1]['content'] = streamedText;
                    }
                    _scrollToBottom();
                  });
                }
              } catch (e) {
                debugPrint('Error parsing chunk: $e');
              }
            }
          }
        },
        onError: (error) {
          debugPrint('Stream error: $error');
          setState(() {
            isThinking = false;
            messages.insert(0, {
              "type": "ai",
              "content": "Error processing your request",
              "isMarkdown": false,
              "timestamp": DateTime.now(),
            });
            _scrollToBottom();
          });
        },
        onDone: () {
          setState(() {
            isThinking = false;
            if (isFirstChunk) {
              messages.insert(0, {
                "type": "ai",
                "content": "No response received",
                "isMarkdown": false,
                "timestamp": DateTime.now(),
              });
              _scrollToBottom();
            }
          });
          client.close();
        },
        cancelOnError: true,
      );

      _subscription = subscription;
    } catch (e) {
      debugPrint('Request failed: $e');
      setState(() {
        isThinking = false;
        messages.insert(0, {
          "type": "ai",
          "content": "Connection error",
          "isMarkdown": false,
          "timestamp": DateTime.now(),
        });
        _scrollToBottom();
      });
    }
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 12,
              width: 12,
              margin: EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                shape: BoxShape.circle,
              ),
            ),
            Container(
              height: 12,
              width: 12,
              margin: EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                shape: BoxShape.circle,
              ),
            ),
            Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message, {int index = 0}) {
    final isUser = message['type'] == 'human';
    final isMarkdown = message['isMarkdown'] == true && !isUser;
    final content = message['content'] ?? '';
    final isLong = content.length > 10000;
    final isExpanded = expandedMessages[index] ?? false;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget messageContent;

    if (isMarkdown) {
      messageContent = MarkdownBody(
        data: isExpanded || !isLong ? content : content.substring(0, 10000) + '...',
        styleSheet: MarkdownStyleSheet.fromTheme(theme),
      );
    } else {
      messageContent = Text(
        isExpanded || !isLong ? content : content.substring(0, 10000) + '...',
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            messageContent,
            if (isLong)
              TextButton(
                onPressed: () {
                  setState(() {
                    expandedMessages[index] = !isExpanded;
                  });

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
                child: Text(isExpanded ? 'Show less' : 'Show more'),
              ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedMessages = [...messages];
    sortedMessages.sort((a, b) {
      final aRaw = a['timestamp'];
      final bRaw = b['timestamp'];

      final aTime = aRaw is DateTime
          ? aRaw
          : DateTime.tryParse(aRaw?.toString() ?? '') ?? DateTime.now();
      final bTime = bRaw is DateTime
          ? bRaw
          : DateTime.tryParse(bRaw?.toString() ?? '') ?? DateTime.now();

      return aTime.compareTo(bTime);
    });
    return Scaffold(
      drawer: ChatSidebar(
        userId: authController.userId.toString(),
        onChatSelected: (chatId) {
          Navigator.pop(context); // Close the drawer
          loadMessagesFromSession(chatId); // Load messages
        },
        onNewChat: () {
          Navigator.of(context).pop();
          setState(() {
            currentSessionId = '';
            messages.clear();
            showWelcome = true;
          });
        },
      ), // Chat drawer
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Ask Chanzo AI",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(LucideIcons.alignLeft, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: showWelcome
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "How can I help you today?",
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: false,
                      itemCount: sortedMessages.length + (isThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        messages.sort((a, b) {
                          final aTime =
                              DateTime.tryParse(a['timestamp'] ?? '') ??
                                  DateTime.now();
                          final bTime =
                              DateTime.tryParse(b['timestamp'] ?? '') ??
                                  DateTime.now();
                          return aTime.compareTo(bTime);
                        });

                        if (index >= messages.length) {
                          return _buildTypingIndicator();
                        }

                        return _buildMessage(messages[index], index: index);
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: !isThinking,
                        decoration: InputDecoration(
                          hintText: "Message Chanzo AI...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.attach_file, color: Colors.grey),
                            onPressed: () {},
                          ),
                        ),
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty && !isThinking) {
                            sendMessage(text);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _controller.text.trim().isNotEmpty && !isThinking
                          ? Color(0xFF3B82F6)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(13),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send,
                          color:
                              _controller.text.trim().isNotEmpty && !isThinking
                                  ? Colors.white
                                  : Colors.grey),
                      onPressed: () {
                        if (_controller.text.trim().isNotEmpty && !isThinking) {
                          sendMessage(_controller.text);
                        }
                      },
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
}
