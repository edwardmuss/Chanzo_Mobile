import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../globalclass/kiotapay_constants.dart';

class ChatSidebar extends StatefulWidget {
  final String userId;
  final Function(String chatId) onChatSelected;
  final Function()? onNewChat;

  const ChatSidebar({
    required this.userId,
    required this.onChatSelected,
    this.onNewChat,
  });

  @override
  State<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar> {
  List<ChatSession> sessions = [];
  Map<String, List<ChatSession>> groupedSessions = {};
  String searchTerm = '';
  String? nextCursor;
  bool isLoading = false;
  bool hasMore = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSessions(initial: true);
  }

  Future<void> fetchSessions({bool initial = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    if (initial) {
      sessions.clear();
      groupedSessions.clear();
      nextCursor = null;
    }

    final baseUrl = "${KiotaPayConstants.fetchSessions}/${widget.userId}/sessions?limit=10";
    final url = Uri.parse(baseUrl +
        (nextCursor != null ? "&cursor=${Uri.encodeComponent(nextCursor!)}" : "") +
        (searchTerm.isNotEmpty ? "&search=${Uri.encodeComponent(searchTerm)}" : ""));
    print("Drawer sessionUrl is $url");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        nextCursor = json['next_cursor'];
        hasMore = json['has_more'] == true;

        final newSessions = data.map((e) => ChatSession.fromJson(e)).toList();
        sessions.addAll(newSessions);

        groupSessions();
      }
    } catch (e) {
      print("Error loading sessions: $e");
    }

    setState(() => isLoading = false);
  }

  void groupSessions() {
    groupedSessions.clear();
    for (var session in sessions) {
      final label = getGroupLabel(session.updatedAt);
      groupedSessions.putIfAbsent(label, () => []).add(session);
    }
  }

  String getGroupLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    if (diff <= 7) return "Last 7 Days";
    if (diff <= 30) return "Last 30 Days";
    return DateFormat('MMMM yyyy').format(date);
  }

  void onSearch(String term) {
    setState(() {
      searchTerm = term.trim();
    });
    fetchSessions(initial: true);
  }

  Future<void> renameSession(ChatSession session) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: session.title);
        return AlertDialog(
          title: Text('Rename Conversation'),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != session.title) {
      final url = Uri.parse('https://ai.chanzo.co.ke/api/v1/sessions/${session.id}');
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': newTitle}),
      );

      if (response.statusCode == 200) {
        setState(() {
          session.title = newTitle;
        });
        fetchSessions(initial: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to rename')));
      }
    }
  }

  Future<void> deleteSession(ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Conversation?"),
        content: Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
        ],
      ),
    );

    if (confirmed == true) {
      final url = Uri.parse('https://ai.chanzo.co.ke/api/v1/sessions/${session.id}');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        setState(() {
          sessions.removeWhere((s) => s.id == session.id);
          groupSessions();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed')));
      }
    }
  }

  Widget buildHighlightedText(String text) {
    if (searchTerm.isEmpty) return Text(text, overflow: TextOverflow.ellipsis);

    final regex = RegExp(RegExp.escape(searchTerm), caseSensitive: false);
    final matches = regex.allMatches(text);

    if (matches.isEmpty) return Text(text, overflow: TextOverflow.ellipsis);

    final spans = <TextSpan>[];
    int last = 0;

    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(backgroundColor: Colors.yellow),
      ));
      last = match.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return Text.rich(TextSpan(children: spans), overflow: TextOverflow.ellipsis);
  }

  Widget buildSessionItem(ChatSession session) {
    return ListTile(
      title: buildHighlightedText(session.title),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'rename') renameSession(session);
          if (value == 'delete') deleteSession(session);
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: () => widget.onChatSelected(session.id),
    );
  }

  Widget _buildShimmerList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Shimmer.fromColors(
            baseColor: isDark ? Colors.black12 : Colors.grey.shade300,
            highlightColor: isDark ? Colors.black54 : Colors.grey.shade100,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0.5,
              color: theme.cardColor,
              child: ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Container(
                  height: 12,
                  width: double.infinity,
                  color: theme.colorScheme.surface,
                ),
                subtitle: Container(
                  height: 10,
                  width: 150,
                  color: theme.colorScheme.surface,
                  margin: const EdgeInsets.only(top: 6),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FilledButton.icon(
                  onPressed: widget.onNewChat,
                icon: const Icon(Icons.add),
                label: const Text("New Chat"),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: "Search chats...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchTerm.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      onSearch('');
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Session List
            Expanded(
              child: groupedSessions.isEmpty && isLoading
                  ? _buildShimmerList()
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: groupedSessions.length,
                itemBuilder: (context, groupIndex) {
                  final label = groupedSessions.keys.elementAt(groupIndex);
                  final items = groupedSessions[label]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      ...items.map((session) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
                        child: Card(
                          elevation: 0.1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: buildHighlightedText(session.title),
                            onTap: () => widget.onChatSelected(session.id),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'rename') renameSession(session);
                                if (value == 'delete') deleteSession(session);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ),
                        ),
                      )),
                    ],
                  );
                },
              ),
            ),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),

            if (hasMore && !isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: OutlinedButton.icon(
                  onPressed: () => fetchSessions(initial: false),
                  icon: const Icon(Icons.expand_more),
                  label: const Text("Load More"),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class ChatSession {
  final String id;
  String title;
  final DateTime updatedAt;

  ChatSession({required this.id, required this.title, required this.updatedAt});

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final parsedValue = jsonDecode(json['value']);
    return ChatSession(
      id: parsedValue['thread_id'],
      title: parsedValue['title'] ?? 'Untitled',
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
