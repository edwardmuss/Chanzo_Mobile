import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'notification_model.dart';
import 'notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
      Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount();
    });

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      Provider.of<NotificationProvider>(context, listen: false).loadMoreNotifications();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Messages'),
            Tab(text: 'Alerts'),
          ],
          onTap: (index) {
            final provider = Provider.of<NotificationProvider>(context, listen: false);
            switch (index) {
              case 0: provider.fetchNotifications(); break;
              case 1: provider.fetchNotifications(tab: 'messages'); break;
              case 2: provider.fetchNotifications(tab: 'alerts'); break;
            }
          },
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(provider, provider.notifications),
              _buildNotificationList(provider, provider.notifications.where((n) => n.type == 'sms').toList()),
              _buildNotificationList(provider, provider.notifications.where((n) => n.type != 'sms').toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationList(NotificationProvider provider, List<NotificationModel> notifications) {
    if (provider.isLoading && notifications.isEmpty) {
      return ListView.builder(
        itemCount: 7,
        itemBuilder: (context, index) => _buildShimmerNotification(),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No notifications found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchNotifications(tab: provider.currentTab),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: notifications.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < notifications.length) {
            return _buildNotificationItem(context, notifications[index]);
          } else {
            return provider.isLoadingMore
                ? _buildLoadingMoreIndicator()
                : SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildShimmerNotification() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 20,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Container(
              width: 200,
              height: 16,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Container(
              width: 150,
              height: 14,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Divider(height: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification.unread
          ? (isDark ? Colors.blue.withOpacity(0.2) : Colors.blue[50])
          : theme.cardColor, // reactive to theme
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForType(notification.type, theme).withOpacity(0.2),
          child: Icon(
            _getIconForType(notification.type),
            color: _getColorForType(notification.type, theme),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.unread ? FontWeight.bold : FontWeight.normal,
            color: theme.textTheme.bodyLarge!.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body,
                style: TextStyle(color: theme.textTheme.bodyMedium!.color)),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall!.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
        trailing: notification.unread
            ? Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        )
            : null,
        onTap: () {
          Provider.of<NotificationProvider>(context, listen: false)
              .markAsRead(notification.id);

          // Trigger UI rebuild to immediately update color
          (context as Element).markNeedsBuild();

          if (notification.link != null) {
            // Handle deep link navigation
          }
        },
      ),
    );
  }

  Color _getColorForType(String type, ThemeData theme) {
    switch (type) {
      case 'sms':
        return theme.colorScheme.primary;
      case 'alert':
        return theme.colorScheme.error;
      case 'message':
        return Colors.green; // you could also use theme.colorScheme.secondary
      default:
        return theme.disabledColor;
    }
  }


  IconData _getIconForType(String type) {
    switch (type) {
      case 'sms': return Icons.message;
      case 'alert': return Icons.warning;
      case 'message': return Icons.mail;
      default: return Icons.notifications;
    }
  }
}