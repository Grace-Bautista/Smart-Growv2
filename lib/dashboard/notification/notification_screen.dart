import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_grow_code/custom_header_button.dart';

class NotificationItem {
  NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.isRead = false,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  bool isRead;
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<NotificationItem> today;
  late List<NotificationItem> yesterday;

  @override
  void initState() {
    super.initState();

    today = [
      NotificationItem(
        title: 'Temperature Alert',
        subtitle:
            'Grow room temperature reached 29.4 C and extra ventilation was recommended.',
        time: 'Just now',
        icon: Icons.thermostat,
        color: const Color(0xFFE76F51),
      ),
      NotificationItem(
        title: 'Humidity Dropped',
        subtitle:
            'Relative humidity fell below 80%. Check misting coverage and bag moisture.',
        time: '10 mins ago',
        icon: Icons.water_drop,
        color: const Color(0xFF2A9D8F),
      ),
      NotificationItem(
        title: 'Low Water Detected',
        subtitle:
            'The refill pump was armed after the tank level was reported low.',
        time: '25 mins ago',
        icon: Icons.opacity,
        color: const Color(0xFF264653),
      ),
    ];

    yesterday = [
      NotificationItem(
        title: 'CO2 Ventilation Triggered',
        subtitle:
            'CO2 rose above the target band and the fan switched into active ventilation.',
        time: 'Yesterday 6:12 PM',
        icon: Icons.air,
        color: const Color(0xFFF4A261),
      ),
      NotificationItem(
        title: 'Sensor Link Restored',
        subtitle:
            'SCD40 communication resumed and live readings returned to the dashboard.',
        time: 'Yesterday 4:45 PM',
        icon: Icons.sensors,
        color: const Color(0xFF6D597A),
      ),
      NotificationItem(
        title: 'Manual Override Used',
        subtitle:
            'An operator manually turned the fan on during a hot afternoon cycle.',
        time: 'Yesterday 2:30 PM',
        icon: Icons.tune,
        color: const Color(0xFF457B9D),
      ),
    ];
  }

  void removeItem(NotificationItem item) {
    setState(() {
      today.remove(item);
      yesterday.remove(item);
    });
  }

  void toggleRead(NotificationItem item) {
    setState(() {
      item.isRead = !item.isRead;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = width * 0.05;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeaderButton(title: 'Notifications'),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF5F1E8), Color(0xFFEAE3D5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: ListView(
                      padding: EdgeInsets.all(padding),
                      children: [
                        const SectionTitle(title: 'Today'),
                        ...today.map(
                          (item) => AnimatedNotificationTile(
                            item: item,
                            onDismiss: () => removeItem(item),
                            onTap: () => toggleRead(item),
                          ),
                        ),
                        SizedBox(height: padding),
                        const SectionTitle(title: 'Yesterday'),
                        ...yesterday.map(
                          (item) => AnimatedNotificationTile(
                            item: item,
                            onDismiss: () => removeItem(item),
                            onTap: () => toggleRead(item),
                          ),
                        ),
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
  const SectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: width * 0.03),
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

  final NotificationItem item;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  State<AnimatedNotificationTile> createState() =>
      _AnimatedNotificationTileState();
}

class _AnimatedNotificationTileState extends State<AnimatedNotificationTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dismissible(
          key: ValueKey(widget.item.title),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => widget.onDismiss(),
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: width * 0.05),
            decoration: BoxDecoration(
              color: const Color(0xFFB56576),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: width * 0.02),
                  padding: EdgeInsets.all(width * 0.045),
                  decoration: BoxDecoration(
                    color: widget.item.isRead
                        ? Colors.white.withOpacity(0.55)
                        : const Color(0xFFEDE6DA).withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: widget.item.color.withOpacity(0.2),
                        child: Icon(widget.item.icon, color: widget.item.color),
                      ),
                      SizedBox(width: width * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.title,
                              style: TextStyle(
                                fontSize: width * 0.048,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: width * 0.01),
                            Text(
                              widget.item.subtitle,
                              style: TextStyle(fontSize: width * 0.04),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.item.isRead)
                        Container(
                          width: width * 0.02,
                          height: width * 0.02,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B6F47),
                            shape: BoxShape.circle,
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
