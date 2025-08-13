import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'notification_model.dart';
import 'notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
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
              _buildNotificationList(provider.notifications),
              _buildNotificationList(provider.notifications.where((n) => n.type == 'sms').toList()),
              _buildNotificationList(provider.notifications.where((n) => n.type != 'sms').toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
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
      onRefresh: () => Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(),
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification.isRead ? Colors.white : Colors.blue[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForType(notification.type).withOpacity(0.2),
          child: Icon(_getIconForType(notification.type)),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        )
            : null,
        onTap: () {
          Provider.of<NotificationProvider>(context, listen: false)
              .markAsRead(notification.id);
          // Handle deep link if available
          if (notification.deepLink != null) {
            // Navigate to deep link
          }
        },
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'sms': return Colors.blue;
      case 'alert': return Colors.red;
      case 'message': return Colors.green;
      default: return Colors.grey;
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