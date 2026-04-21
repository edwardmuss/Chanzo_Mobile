import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';
import '../../widgets/error.dart';

class ManageSubjectScreen extends StatefulWidget {
  final int subjectId;
  final int classId; // Or classId, depending on your DB structure
  final String subjectName;

  const ManageSubjectScreen({
    super.key,
    required this.subjectId,
    required this.classId,
    required this.subjectName,
  });

  @override
  State<ManageSubjectScreen> createState() => _ManageSubjectScreenState();
}

class _ManageSubjectScreenState extends State<ManageSubjectScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _strands = [];

  @override
  void initState() {
    super.initState();
    _fetchSubjectTree();
  }

  Future<void> _fetchSubjectTree() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Pass the subject and class parameters to fetch the specific tree
      final response = await DioHelper().get(
        KiotaPayConstants.subjectTree,
        queryParameters: {
          'subject_id': widget.subjectId,
          'class_id': widget.classId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _strands = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // --- CRUD Operations ---

  void _showAddEditBottomSheet({
    required String type, // 'strand', 'substrand', 'activity'
    Map<String, dynamic>? existingData,
    int? parentId, // Subject ID for Strand, Strand ID for SubStrand, etc.
  }) {
    final TextEditingController nameCtrl = TextEditingController(text: existingData?['name'] ?? '');
    final TextEditingController descCtrl = TextEditingController(text: existingData?['description'] ?? '');
    final bool isEdit = existingData != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${isEdit ? 'Edit' : 'Add'} ${type.capitalizeFirst}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            if (type != 'activity') // Assuming activities might not need descriptions, adjust if they do!
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChanzoColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;

                  Get.back(); // Close bottom sheet

                  Map<String, dynamic> payload = {
                    'name': nameCtrl.text,
                    'description': descCtrl.text
                  };

                  String endpoint = '';

                  // Determine the API endpoint and parent IDs based on what we are adding
                  if (type == 'strand') {
                    endpoint = KiotaPayConstants.strands;
                    if (!isEdit) {
                      payload['subject_id'] = widget.subjectId;
                      payload['class_id'] = widget.classId;
                    }
                  } else if (type == 'substrand') {
                    endpoint = KiotaPayConstants.subStrands;
                    if (!isEdit) payload['strand_id'] = parentId;
                  } else if (type == 'activity') {
                    endpoint = KiotaPayConstants.activities;
                    if (!isEdit) payload['substrand_id'] = parentId;
                  }

                  try {
                    if (isEdit) {
                      await DioHelper().put('$endpoint/${existingData!['id']}', data: payload);
                    } else {
                      await DioHelper().post(endpoint, data: payload);
                    }
                    _fetchSubjectTree();
                    Get.snackbar('Success', '${type.capitalizeFirst} saved!', backgroundColor: Colors.green, colorText: Colors.white);
                  } catch (e) {
                    Get.snackbar('Error', 'Failed to save ${type}.');
                  }
                },
                child: Text(isEdit ? "Update" : "Save"),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _deleteNode(String type, int id) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'Delete ${type.capitalizeFirst}?',
      desc: 'Are you sure? This may delete all nested items under it.',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        String endpoint = '';
        if (type == 'strand') endpoint = KiotaPayConstants.strands;
        else if (type == 'substrand') endpoint = KiotaPayConstants.subStrands;
        else if (type == 'activity') endpoint = KiotaPayConstants.activities;

        try {
          await DioHelper().delete('$endpoint/$id');
          _fetchSubjectTree();
          Get.snackbar('Success', 'Deleted successfully.', backgroundColor: Colors.green, colorText: Colors.white);
        } catch(e) {
          Get.snackbar('Error', 'Failed to delete.');
        }
      },
    ).show();
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBottomSheet(type: 'strand', parentId: widget.subjectId),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Strand", style: TextStyle(color: Colors.white)),
        backgroundColor: ChanzoColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? ErrorWidgetUniversal(title: "Failed to load", description: "Could not fetch subject data.", onRetry: _fetchSubjectTree)
          : RefreshIndicator(
        onRefresh: _fetchSubjectTree,
        color: ChanzoColors.primary,
        child: _strands.isEmpty
            ? _buildEmptyState(isDark)
            : ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16),
          itemCount: _strands.length,
          itemBuilder: (context, index) {
            final strand = _strands[index];
            return _buildStrandNode(strand, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildStrandNode(Map<String, dynamic> strand, bool isDark) {
    final List subStrands = strand['substrands'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 2,
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.transparent),
      ),
      child: ExpansionTile(
        title: Text(strand['name'] ?? 'Unknown Strand', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("${subStrands.length} Sub-strands", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        childrenPadding: EdgeInsets.zero,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: ChanzoColors.primary),
              onPressed: () => _showAddEditBottomSheet(type: 'substrand', parentId: strand['id']),
              tooltip: "Add Sub-strand",
            ),
            _buildActionMenu('strand', strand),
          ],
        ),
        children: [
          const Divider(height: 1),
          if (subStrands.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("No sub-strands added yet.", style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
            )
          else
            ...subStrands.map((subStrand) => _buildSubStrandNode(subStrand, isDark)).toList(),
        ],
      ),
    );
  }

  Widget _buildSubStrandNode(Map<String, dynamic> subStrand, bool isDark) {
    final List activities = subStrand['activities'] ?? [];

    return Container(
      color: isDark ? Colors.black12 : Colors.grey.shade50,
      child: ExpansionTile(
        title: Text(subStrand['name'] ?? 'Unknown Sub-strand', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text("${activities.length} Activities", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
        tilePadding: const EdgeInsets.only(left: 32, right: 16),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add, size: 20, color: ChanzoColors.secondary),
              onPressed: () => _showAddEditBottomSheet(type: 'activity', parentId: subStrand['id']),
              tooltip: "Add Activity",
            ),
            _buildActionMenu('substrand', subStrand),
          ],
        ),
        children: [
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("No activities added yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            )
          else
            ...activities.map((activity) {
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 48, right: 16),
                dense: true,
                leading: const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                title: Text(activity['name'] ?? 'Unknown', style: const TextStyle(fontSize: 14)),
                trailing: _buildActionMenu('activity', activity),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionMenu(String type, Map<String, dynamic> data) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'edit') {
          _showAddEditBottomSheet(type: type, existingData: data);
        } else if (value == 'delete') {
          _deleteNode(type, data['id']);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Subject Data",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            "Click the + button to add the first Strand.",
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}