import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final String name;
  final double radius;
  final Color backgroundColor;
  final Color textColor;

  const UserAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.radius = 20,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = context.watch<AuthProvider>().getAvatarBytes(userId);
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes == null
          ? Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: TextStyle(
                color: textColor,
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
