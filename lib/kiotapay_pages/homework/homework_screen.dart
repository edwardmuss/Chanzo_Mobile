import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

import '../../globalclass/global_methods.dart';
import '../../widgets/shimmer_widget.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final class_id = authController.selectedStudentClassId;
  final stream_id = authController.selectedStudentStreamId;

  List<dynamic> homeworks = [];
  List<dynamic> filteredHomeworks = [];

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasError = false;
  int currentPage = 1;
  int lastPage = 1;

  @override
  void initState() {
    super.initState();
    fetchHomework();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(() {
      setState(() {
        filterHomeworks();
      });
    });
  }

  Future<void> fetchHomework({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      homeworks.clear();
    }

    try {
      setState(() {
        if (!refresh && currentPage > 1) {
          isLoadingMore = true;
        } else {
          isLoading = true;
        }
      });

      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse(
            "${KiotaPayConstants.getStudentHomeWork}/${class_id}/${stream_id}?page=$currentPage"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        final pagination = decoded['pagination'];

        homeworks.addAll(data);
        currentPage++;
        lastPage = pagination['last_page'];
        filterHomeworks();
      } else {
        hasError = true;
      }
    } catch (e) {
      hasError = true;
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoadingMore &&
        currentPage <= lastPage) {
      fetchHomework();
    }
  }

  void filterHomeworks() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredHomeworks = homeworks;
    } else {
      filteredHomeworks = homeworks.where((hw) {
        final subject = hw['subject']['name']?.toLowerCase() ?? '';
        final desc = hw['description']?.toLowerCase() ?? '';
        return subject.contains(query) || desc.contains(query);
      }).toList();
    }
  }

  void _showHomeworkDetails(dynamic homework) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homework['subject']['name'] ?? 'No Subject',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Class: ${homework['class']['name']}, Stream: ${homework['stream']['name']}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  "Created By: ${homework['created_by']['first_name']} ${homework['created_by']['last_name']}",
                ),
                const SizedBox(height: 12),
                Text(
                  "Description:",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  homework['description']
                      ?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openFile(context, homework['file']);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text("Download File"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: ChanzoColors.primary,
                      foregroundColor: ChanzoColors.white),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _submitHomework(homework),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Submit Homework"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: ChanzoColors.secondary,
                      foregroundColor: ChanzoColors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitHomework(dynamic homework) async {
    final token = await storage.read(key: 'token');
    Navigator.of(context).pop();
    final url =
        "${KiotaPayConstants.baseUrl}/homework/${homework['class_id']}/${homework['stream_id']}";
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Homework submitted successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit homework.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Homework")),
      body: RefreshIndicator(
        onRefresh: () => fetchHomework(refresh: true),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          children: [
            // 👨‍🎓 Student Info Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                      authController.selectedStudentAvatar ??
                          'https://via.placeholder.com/150'),
                  radius: 30,
                ),
                title: Text(authController.selectedStudentName ?? ''),
                subtitle: Text(
                    "Adm No: ${authController.selectedStudentAdmissionNumber}\nClass: ${authController.selectedStudentClassName} (${authController.selectedStudentStreamName})"),
              ),
            ),
            const SizedBox(height: 12),
            // 🔍 Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search homework...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            // 📝 Homework List
            if (isLoading && homeworks.isEmpty)
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const ShimmerWidget.circular(height: 50, width: 50),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerWidget.rectangular(
                                height: 16, width: double.infinity),
                            SizedBox(height: 8),
                            ShimmerWidget.rectangular(height: 14, width: 150),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            else if (hasError)
              Center(
                child: Text("Failed to load homework. Pull to refresh."),
              )
            else
              ...filteredHomeworks.map((hw) {
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ChanzoColors.secondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      title: Text(
                        hw['subject']['name'] ?? 'No Subject',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: () => _showHomeworkDetails(hw),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Important for proper sizing
                          children: [
                            Text(
                              'View',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      onTap: () => _showHomeworkDetails(hw),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 24,
                      endIndent: 24,
                      // color: Colors.blue[900],
                    ),
                  ],
                );
              }).toList(),
            if (isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              )
          ],
        ),
      ),
    );
  }
}
