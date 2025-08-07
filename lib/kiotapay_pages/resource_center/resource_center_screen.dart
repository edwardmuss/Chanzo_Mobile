import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../globalclass/global_methods.dart';

class ResourceCenterScreen extends StatefulWidget {
  const ResourceCenterScreen({super.key});

  @override
  State<ResourceCenterScreen> createState() => _ResourceCenterScreenState();
}

class _ResourceCenterScreenState extends State<ResourceCenterScreen> {
  List<dynamic> resourceTypes = [];
  List<dynamic> filteredResources = [];
  int currentPage = 1;
  int lastPage = 1;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasError = false;
  String searchQuery = "";

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchResources();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
        filterResources();
      });
    });
  }

  Future<void> fetchResources({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      resourceTypes.clear();
      filteredResources.clear();
    }

    try {
      if (currentPage > lastPage) return;

      setState(() {
        if (!refresh && currentPage > 1) {
          isLoadingMore = true;
        } else {
          isLoading = true;
          hasError = false;
        }
      });

      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse("${KiotaPayConstants.getResourceCenter}?page=$currentPage"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        final pagination = decoded['pagination'];

        resourceTypes.addAll(data);
        filterResources();
        currentPage++;
        lastPage = pagination['last_page'];
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

  void filterResources() {
    List<dynamic> allResources = [];
    for (var type in resourceTypes) {
      if (type['resources'] != null) {
        allResources.addAll(type['resources']);
      }
    }

    if (searchQuery.isEmpty) {
      filteredResources = allResources;
    } else {
      filteredResources = allResources.where((resource) {
        final title = resource['title']?.toLowerCase() ?? "";
        final description = resource['description']?.toLowerCase() ?? "";
        return title.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !isLoadingMore &&
        currentPage <= lastPage) {
      fetchResources();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resource Center"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search resources...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Failed to load resources."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => fetchResources(refresh: true),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () => fetchResources(refresh: true),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: filteredResources.length + 1,
                itemBuilder: (context, index) {
                  if (index < filteredResources.length) {
                    final resource = filteredResources[index];
                    final uploadDate = DateFormat.yMMMMd().format(
                        DateTime.parse(resource['upload_date']));
                    final title = resource['title'] ?? "Untitled";
                    final description = resource['description']
                        ?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'),
                        '') ??
                        "";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              uploadDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  ChanzoColors.secondary,
                                  foregroundColor: ChanzoColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => openFile(context,
                                    resource['file']),
                                icon: const Icon(Icons.download),
                                label: const Text("Download"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                          child: CircularProgressIndicator()),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
