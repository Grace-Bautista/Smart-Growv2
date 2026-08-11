import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_grow_code/custom_header_button.dart';
import 'package:smart_grow_code/services/alert_store.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();

    _reloadAlerts();

    // Rebuild this screen whenever AlertStore changes.
    AlertStore.revision.addListener(_onAlertStoreChanged);
  }

  @override
  void dispose() {
    AlertStore.revision.removeListener(_onAlertStoreChanged);
    super.dispose();
  }

  void _onAlertStoreChanged() {
    if (!mounted) return;

    setState(() {
      _items = AlertStore.all();
    });
  }

  void _reloadAlerts() {
    _items = AlertStore.all();
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    final key = item['_key'];

    if (key == null) return;

    // Notifications should become read when opened.
    // We do not toggle them back to unread.
    if (item['read'] != true) {
      await AlertStore.markRead(key);
    }
  }

  void _removeItem(Map<String, dynamic> item) {
    final key = item['_key'];

    if (key == null) return;

    // Remove immediately from the visible list so Dismissible
    // does not remain in the widget tree.
    setState(() {
      _items.removeWhere(
        (alert) => alert['_key'] == key,
      );
    });

    AlertStore.remove(key);
  }

  Future<void> _markAllRead() async {
    await AlertStore.markAllRead();
  }

  Future<void> _clearAll() async {
    if (_items.isEmpty) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Notifications'),
          content: const Text(
            'Are you sure you want to delete all notifications?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      setState(() {
        _items.clear();
      });

      await AlertStore.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = width * 0.05;

    final grouped = AlertStore.groupByDay(_items);

    final today = grouped['Today'] ?? [];
    final yesterday = grouped['Yesterday'] ?? [];
    final earlier = grouped['Earlier'] ?? [];

    final hasUnread = _items.any(
      (item) => item['read'] != true,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeaderButton(
              title: 'Notifications',
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF5F1E8),
                      Color(0xFFEAE3D5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 850,
                    ),
                    child: _items.isEmpty
                        ? const _EmptyNotificationView()
                        : ListView(
                            padding: EdgeInsets.all(padding),
                            children: [
                              // -----------------------------------------
                              // NOTIFICATION ACTIONS
                              // -----------------------------------------
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: hasUnread
                                        ? _markAllRead
                                        : null,
                                    icon: const Icon(
                                      Icons.done_all_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Mark all read',
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  IconButton(
                                    tooltip:
                                        'Clear all notifications',
                                    onPressed: _clearAll,
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),

                              // -----------------------------------------
                              // TODAY
                              // -----------------------------------------
                              if (today.isNotEmpty) ...[
                                const SectionTitle(
                                  title: 'Today',
                                ),

                                ...today.map(
                                  (item) =>
                                      AnimatedNotificationTile(
                                    key: ValueKey(
                                      'today-${item['_key']}',
                                    ),
                                    item: item,
                                    onDismiss: () {
                                      _removeItem(item);
                                    },
                                    onTap: () {
                                      _markRead(item);
                                    },
                                  ),
                                ),
                              ],

                              // -----------------------------------------
                              // YESTERDAY
                              // -----------------------------------------
                              if (yesterday.isNotEmpty) ...[
                                SizedBox(
                                  height: padding * 0.5,
                                ),

                                const SectionTitle(
                                  title: 'Yesterday',
                                ),

                                ...yesterday.map(
                                  (item) =>
                                      AnimatedNotificationTile(
                                    key: ValueKey(
                                      'yesterday-${item['_key']}',
                                    ),
                                    item: item,
                                    onDismiss: () {
                                      _removeItem(item);
                                    },
                                    onTap: () {
                                      _markRead(item);
                                    },
                                  ),
                                ),
                              ],

                              // -----------------------------------------
                              // EARLIER
                              // -----------------------------------------
                              if (earlier.isNotEmpty) ...[
                                SizedBox(
                                  height: padding * 0.5,
                                ),

                                const SectionTitle(
                                  title: 'Earlier',
                                ),

                                ...earlier.map(
                                  (item) =>
                                      AnimatedNotificationTile(
                                    key: ValueKey(
                                      'earlier-${item['_key']}',
                                    ),
                                    item: item,
                                    onDismiss: () {
                                      _removeItem(item);
                                    },
                                    onTap: () {
                                      _markRead(item);
                                    },
                                  ),
                                ),
                              ],

                              SizedBox(height: padding),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: width * 0.03,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: width * 0.05,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5A534A),
        ),
      ),
    );
  }
}

class AnimatedNotificationTile extends StatefulWidget {
  const AnimatedNotificationTile({
    super.key,
    required this.item,
    required this.onDismiss,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  State<AnimatedNotificationTile> createState() =>
      _AnimatedNotificationTileState();
}

class _AnimatedNotificationTileState
    extends State<AnimatedNotificationTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 400,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final title =
        widget.item['title']?.toString() ??
        'Smart-Grow Alert';

    final subtitle =
        widget.item['subtitle']?.toString() ?? '';

    final iconKey =
        widget.item['iconKey']?.toString() ??
        'notification';

    final colorValue =
        (widget.item['colorValue'] as num?)
            ?.toInt() ??
        0xFF8B6F47;

    final isRead =
        widget.item['read'] == true;

    final timestamp = DateTime.tryParse(
      widget.item['timestamp']?.toString() ?? '',
    );

    final color = Color(colorValue);
    final icon = _iconFromKey(iconKey);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dismissible(
          key: ValueKey(
            'dismiss-${widget.item['_key']}',
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            widget.onDismiss();
          },
          background: Container(
            alignment: Alignment.centerRight,
            margin: EdgeInsets.symmetric(
              vertical: width * 0.02,
            ),
            padding: EdgeInsets.only(
              right: width * 0.05,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFB56576),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delete_rounded,
              color: Colors.white,
            ),
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 12,
                  sigmaY: 12,
                ),
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(
                    vertical: width * 0.02,
                  ),
                  padding: EdgeInsets.all(
                    width * 0.045,
                  ),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.white.withValues(
                            alpha: 0.55,
                          )
                        : const Color(
                            0xFFEDE6DA,
                          ).withValues(
                            alpha: 0.75,
                          ),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: isRead
                          ? Colors.white.withValues(
                              alpha: 0.35,
                            )
                          : const Color(
                              0xFF8B6F47,
                            ).withValues(
                              alpha: 0.18,
                            ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            color.withValues(
                          alpha: 0.16,
                        ),
                        child: Icon(
                          icon,
                          color: color,
                        ),
                      ),

                      SizedBox(
                        width: width * 0.04,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize:
                                          width * 0.045,
                                      fontWeight: isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      color: const Color(
                                        0xFF263A2A,
                                      ),
                                    ),
                                  ),
                                ),

                                if (!isRead) ...[
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin:
                                        const EdgeInsets.only(
                                      top: 5,
                                    ),
                                    decoration:
                                        const BoxDecoration(
                                      color: Color(
                                        0xFF8B6F47,
                                      ),
                                      shape:
                                          BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            SizedBox(
                              height: width * 0.012,
                            ),

                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize:
                                    width * 0.038,
                                height: 1.35,
                                color: const Color(
                                  0xFF5A534A,
                                ),
                              ),
                            ),

                            if (timestamp != null) ...[
                              SizedBox(
                                height:
                                    width * 0.018,
                              ),

                              Text(
                                _formatNotificationTime(
                                  context,
                                  timestamp,
                                ),
                                style: TextStyle(
                                  fontSize:
                                      width * 0.032,
                                  fontWeight:
                                      FontWeight.w500,
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationView extends StatelessWidget {
  const _EmptyNotificationView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF537D42,
                ).withValues(
                  alpha: 0.12,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 34,
                color: Color(0xFF537D42),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF263A2A),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'System alerts and sensor warnings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps the string stored in Hive to the icon displayed by the UI.
///
/// This keeps Flutter IconData objects out of Hive storage.
IconData _iconFromKey(String key) {
  switch (key) {
    case 'temperature':
    case 'thermostat':
      return Icons.thermostat_rounded;

    case 'humidity':
    case 'water_drop':
      return Icons.water_drop_rounded;

    case 'water':
    case 'waterLevel':
    case 'water_level':
    case 'opacity':
      return Icons.opacity_rounded;

    case 'co2':
    case 'air':
      return Icons.air_rounded;

    case 'sensor':
    case 'sensors':
      return Icons.sensors_rounded;

    case 'sensors_off':
      return Icons.sensors_off_rounded;

    case 'device':
    case 'wifi':
      return Icons.wifi_rounded;

    case 'wifi_off':
    case 'offline':
      return Icons.wifi_off_rounded;

    case 'humidifier':
      return Icons.water_rounded;

    case 'fan':
    case 'ventFan':
      return Icons.air_rounded;

    case 'uv':
    case 'uvLight':
      return Icons.light_mode_rounded;

    case 'refillPump':
    case 'pump':
      return Icons.water_damage_rounded;

    case 'fault':
    case 'error':
      return Icons.error_outline_rounded;

    case 'warning':
      return Icons.warning_amber_rounded;

    case 'success':
      return Icons.check_circle_outline_rounded;

    default:
      return Icons.notifications_rounded;
  }
}
/// Creates user-friendly time labels without needing the intl package.
///
/// Examples:
/// Just now
/// 8 mins ago
/// 2 hrs ago
/// Yesterday • 6:30 PM
/// 8/8/2026 • 4:15 PM
String _formatNotificationTime(
  BuildContext context,
  DateTime timestamp,
) {
  final now = DateTime.now();

  final difference = now.difference(timestamp);

  final timestampDay = DateTime(
    timestamp.year,
    timestamp.month,
    timestamp.day,
  );

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final yesterday = today.subtract(
    const Duration(days: 1),
  );

  if (timestampDay == today) {
    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;

      return '$minutes min${minutes == 1 ? '' : 's'} ago';
    }

    final hours = difference.inHours;

    return '$hours hr${hours == 1 ? '' : 's'} ago';
  }

  final time = TimeOfDay.fromDateTime(
    timestamp,
  ).format(context);

  if (timestampDay == yesterday) {
    return 'Yesterday • $time';
  }

  final date = MaterialLocalizations.of(
    context,
  ).formatShortDate(timestamp);

  return '$date • $time';
}