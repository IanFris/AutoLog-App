import 'package:flutter/material.dart';

class ServiceType {
  final int id;
  final String name;
  final int defaultKmInterval;
  final int defaultMonthInterval;
  final String icon;

  ServiceType({
    required this.id,
    required this.name,
    required this.defaultKmInterval,
    required this.defaultMonthInterval,
    this.icon = 'build',
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) {
    return ServiceType(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      defaultKmInterval: (json['default_km_interval'] as num?)?.toInt() ?? 3000,
      defaultMonthInterval: (json['default_month_interval'] as num?)?.toInt() ?? 3,
      icon: json['icon'] as String? ?? 'build',
    );
  }

  IconData get iconData {
    switch (icon) {
      case 'opacity':
        return Icons.opacity;
      case 'settings':
        return Icons.settings;
      case 'album':
        return Icons.album_outlined;
      case 'flash_on':
        return Icons.flash_on;
      case 'air':
        return Icons.air;
      case 'adjust':
        return Icons.adjust;
      case 'battery_charging_full':
        return Icons.battery_charging_full;
      case 'sync':
        return Icons.sync;
      case 'waves':
        return Icons.waves;
      default:
        return Icons.build;
    }
  }

  Color get color {
    switch (icon) {
      case 'opacity':
        return const Color(0xFFEAB308);
      case 'settings':
        return const Color(0xFFF97316);
      case 'album':
        return const Color(0xFFEF4444);
      case 'flash_on':
        return const Color(0xFF8B5CF6);
      case 'air':
        return const Color(0xFF14B8A6);
      case 'adjust':
        return const Color(0xFF64748B);
      case 'battery_charging_full':
        return const Color(0xFF10B981);
      case 'sync':
        return const Color(0xFFD97706);
      case 'waves':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF0D9488);
    }
  }
}
