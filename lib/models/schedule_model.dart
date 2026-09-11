import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DaySchedule extends Equatable {
  final List<String> monday;
  final List<String> tuesday;
  final List<String> wednesday;
  final List<String> thursday;
  final List<String> friday;
  final List<String> saturday;
  final List<String> sunday;

  const DaySchedule({
    this.monday = const [],
    this.tuesday = const [],
    this.wednesday = const [],
    this.thursday = const [],
    this.friday = const [],
    this.saturday = const [],
    this.sunday = const [],
  });

  static List<String> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    if (data is String) {
      final s = data.trim();
      if (s == 'off' || s.isEmpty) return [];
      return [s];
    }
    return [];
  }

  factory DaySchedule.fromJson(dynamic json) {
    if (json == null || json is! Map) return const DaySchedule();
    return DaySchedule(
      monday: _parseList(json['monday']),
      tuesday: _parseList(json['tuesday']),
      wednesday: _parseList(json['wednesday']),
      thursday: _parseList(json['thursday']),
      friday: _parseList(json['friday']),
      saturday: _parseList(json['saturday']),
      sunday: _parseList(json['sunday']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
    };
  }

  List<String> shiftsForDay(int weekday) {
    switch (weekday) {
      case 1:
        return monday;
      case 2:
        return tuesday;
      case 3:
        return wednesday;
      case 4:
        return thursday;
      case 5:
        return friday;
      case 6:
        return saturday;
      case 7:
        return sunday;
      default:
        return [];
    }
  }

  @override
  List<Object?> get props => [monday, tuesday, wednesday, thursday, friday, saturday, sunday];
}

class ScheduleModel extends Equatable {
  final String id;
  final String storeId;
  final String weekStart; // YYYY-MM-DD (Thứ Hai đầu tuần)
  final Map<String, DaySchedule> shifts; // userId -> DaySchedule

  const ScheduleModel({
    required this.id,
    required this.storeId,
    required this.weekStart,
    required this.shifts,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json, String id) {
    final parsedShifts = <String, DaySchedule>{};

    // 1. Cấu trúc Map lồng: json['shifts'] = { 'userId': { 'monday': [...] } }
    final shiftsData = json['shifts'];
    if (shiftsData is Map) {
      for (final entry in shiftsData.entries) {
        final key = entry.key.toString();
        if (entry.value != null) {
          parsedShifts[key] = DaySchedule.fromJson(entry.value);
        }
      }
    }

    // 2. Cấu trúc flattened: 'shifts.<userId>'
    for (final entry in json.entries) {
      if (entry.key.startsWith('shifts.') && entry.key.length > 7) {
        final userId = entry.key.substring(7);
        if (entry.value != null && !parsedShifts.containsKey(userId)) {
          parsedShifts[userId] = DaySchedule.fromJson(entry.value);
        }
      }
    }

    return ScheduleModel(
      id: id,
      storeId: json['storeId'] as String? ?? '',
      weekStart: json['weekStart'] as String? ?? id,
      shifts: parsedShifts,
    );
  }

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();
    if (rawData == null || rawData is! Map) {
      return ScheduleModel(
        id: doc.id,
        storeId: '',
        weekStart: doc.id,
        shifts: const {},
      );
    }
    final data = Map<String, dynamic>.from(rawData);
    return ScheduleModel.fromJson(data, doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'weekStart': weekStart,
      'shifts': shifts.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  ScheduleModel copyWith({
    String? id,
    String? storeId,
    String? weekStart,
    Map<String, DaySchedule>? shifts,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      weekStart: weekStart ?? this.weekStart,
      shifts: shifts ?? Map.from(this.shifts),
    );
  }

  DaySchedule? getScheduleForUser(String userId) => shifts[userId];

  @override
  List<Object?> get props => [id, storeId, weekStart, shifts];
}
