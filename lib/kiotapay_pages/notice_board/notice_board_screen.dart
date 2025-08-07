import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';
import '../../widgets/shimmer_widget.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = false;
  bool isLoadingMore = false;
  int currentPage = 1;
  int lastPage = 1;
  List<dynamic> notices = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchNotices();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchNotices({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      notices.clear();
    }

    setState(() => refresh ? isLoading = true : isLoadingMore = true);

    try {
      final response = await DioHelper().get(
        KiotaPayConstants.getNotices,
        queryParameters: {
          'page': currentPage,
          if (searchQuery.isNotEmpty) 'searchQuery': searchQuery
        },
      );

      final jsonResponse = response.data;

      if (jsonResponse['success'] == true) {
        final List<dynamic> fetchedNotices = jsonResponse['data'];
        final pagination = jsonResponse['pagination'];

        setState(() {
          notices.addAll(fetchedNotices);
          lastPage = pagination['last_page'];
        });
      } else {
        Get.snackbar("Error", jsonResponse['message'] ?? "Failed to fetch notices");
      }
    } on DioError catch (e) {
      if (e.response != null) {
        Get.snackbar("Error", "Server: ${e.response?.statusCode} ${e.response?.statusMessage}");
      } else {
        Get.snackbar("Error", "Network Error: ${e.message}");
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e");
    }

    setState(() {
      isLoading = false;
      isLoadingMore = false;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        currentPage < lastPage &&
        !isLoadingMore) {
      currentPage++;
      fetchNotices();
    }
  }

  Future<void> _onRefresh() async {
    await fetchNotices(refresh: true);
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value.trim();
      currentPage = 1;
      notices.clear();
    });
    fetchNotices(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search notices...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: Builder(
                builder: (context) {
                  if (isLoading && notices.isEmpty) {
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: 8,
                      itemBuilder: (context, index) =>
                      const ShimmerWidget.rectangular(
                        height: 80,
                        width: double.infinity,
                      ),
                    );
                  }

                  if (notices.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            "No Notices Found",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      ],
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: notices.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < notices.length) {
                        final notice = notices[index];
                        return _buildNoticeCard(notice);
                      } else {
                        return const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(dynamic notice) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.notifications, color: ChanzoColors.primary),
        title: Text(
          notice['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          notice['message'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showNoticeDetails(notice),
      ),
    );
  }

  void _showNoticeDetails(dynamic notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              Text(
                notice['title'],
                style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(notice['message']),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Posted: ${formatNoticeDate(notice['start_date'])}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ElevatedButton.icon(
              //   onPressed: () {
              //     openFile(context, "https://example.com/file.pdf");
              //   },
              //   icon: const Icon(Icons.download),
              //   label: const Text("Download Attachment"),
              // ),
            ],
          ),
        );
      },
    );
  }
}
