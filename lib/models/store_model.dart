import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
class ShiftDefinition extends Equatable {
  final String id;
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isProduction;

  const ShiftDefinition({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.isProduction = false,
  });

  String get startTimeStr =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  String get endTimeStr =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  String get timeRange => '$startTimeStr - $endTimeStr';

  double get totalHours {
    final start = startHour * 60 + startMinute;
    var end = endHour * 60 + endMinute;
    if (end < start) end += 24 * 60;
    return (end - start) / 60.0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
    'isProduction': isProduction,
  };

  factory ShiftDefinition.fromJson(Map<String, dynamic> json) => ShiftDefinition(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    startHour: (json['startHour'] as int?) ?? 8,
    startMinute: (json['startMinute'] as int?) ?? 0,
    endHour: (json['endHour'] as int?) ?? 16,
    endMinute: (json['endMinute'] as int?) ?? 0,
    isProduction: json['isProduction'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, name, startHour, startMinute, endHour, endMinute, isProduction];
}

class DepartmentDefinition extends Equatable {
  final String id;
  final String name;
  final String shortName;

  const DepartmentDefinition({
    required this.id,
    required this.name,
    required this.shortName,
  });

  factory DepartmentDefinition.fromJson(Map<String, dynamic> json) => DepartmentDefinition(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    shortName: json['shortName'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
  };

  @override
  List<Object?> get props => [id, name, shortName];
}

class StoreWifi extends Equatable {
  final String name;
  final String ip;
  final DateTime? createdAt;

  const StoreWifi({
    required this.name,
    required this.ip,
    this.createdAt,
  });

  factory StoreWifi.fromJson(Map<String, dynamic> json) => StoreWifi(
    name: json['name'] as String? ?? 'WiFi',
    ip: json['ip'] as String? ?? '',
    createdAt: json['createdAt'] is Timestamp
        ? (json['createdAt'] as Timestamp).toDate()
        : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'ip': ip,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
  };

  @override
  List<Object?> get props => [name, ip, createdAt];
}

class StoreLocation extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  const StoreLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100,
  });

  factory StoreLocation.fromJson(Map<String, dynamic> json) => StoreLocation(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Vị trí',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    radiusMeters: (json['radiusMeters'] as num?)?.toInt() ?? 100,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
  };

  StoreLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) => StoreLocation(
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusMeters: radiusMeters ?? this.radiusMeters,
  );

  @override
  List<Object?> get props => [id, name, latitude, longitude, radiusMeters];
}

class StorePerformanceStandards extends Equatable {
  final int drinkStandardSeconds;
  final int cakeStandardSeconds;
  final int orderStandardSeconds;

  const StorePerformanceStandards({
    this.drinkStandardSeconds = 120,
    this.cakeStandardSeconds = 120,
    this.orderStandardSeconds = 180,
  });

  factory StorePerformanceStandards.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StorePerformanceStandards();
    return StorePerformanceStandards(
      drinkStandardSeconds: (json['drinkStandardSeconds'] as num?)?.toInt() ?? 120,
      cakeStandardSeconds: (json['cakeStandardSeconds'] as num?)?.toInt() ?? 120,
      orderStandardSeconds: (json['orderStandardSeconds'] as num?)?.toInt() ?? 180,
    );
  }

  Map<String, dynamic> toJson() => {
    'drinkStandardSeconds': drinkStandardSeconds,
    'cakeStandardSeconds': cakeStandardSeconds,
    'orderStandardSeconds': orderStandardSeconds,
  };

  StorePerformanceStandards copyWith({
    int? drinkStandardSeconds,
    int? cakeStandardSeconds,
    int? orderStandardSeconds,
  }) => StorePerformanceStandards(
    drinkStandardSeconds: drinkStandardSeconds ?? this.drinkStandardSeconds,
    cakeStandardSeconds: cakeStandardSeconds ?? this.cakeStandardSeconds,
    orderStandardSeconds: orderStandardSeconds ?? this.orderStandardSeconds,
  );

  @override
  List<Object?> get props => [drinkStandardSeconds, cakeStandardSeconds, orderStandardSeconds];
}

class EndSessionCriterionModel extends Equatable {
  final String id;
  final String title;
  final String type; // 'checkbox', 'number', 'text', 'rating'
  final bool isRequired;
  final int order;
  final String? helperText;

  const EndSessionCriterionModel({
    required this.id,
    required this.title,
    this.type = 'checkbox',
    this.isRequired = true,
    this.order = 0,
    this.helperText,
  });

  factory EndSessionCriterionModel.fromJson(Map<String, dynamic> json) {
    return EndSessionCriterionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'checkbox',
      isRequired: json['isRequired'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
      helperText: json['helperText'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'isRequired': isRequired,
    'order': order,
    if (helperText != null) 'helperText': helperText,
  };

  EndSessionCriterionModel copyWith({
    String? id,
    String? title,
    String? type,
    bool? isRequired,
    int? order,
    String? helperText,
  }) => EndSessionCriterionModel(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    isRequired: isRequired ?? this.isRequired,
    order: order ?? this.order,
    helperText: helperText ?? this.helperText,
  );

  @override
  List<Object?> get props => [id, title, type, isRequired, order, helperText];
}

class StoreModel extends Equatable {
  final String id;
  final String name;
  final String code; // 6-char alphanumeric
  final String ownerId;
  final String? address;
  final String? networkIP;
  final double? latitude;
  final double? longitude;
  final int radiusMeters; // default 100
  final List<StoreLocation> locations;
  final DateTime createdAt;
  final List<ShiftDefinition> customShifts;
  final List<DepartmentDefinition> departments;
  final num? deliveryAllowance;
  final num? giaoHangAllowance;
  final bool deliveryEnabled;
  final bool giaoHangEnabled;
  final String? themeColor;
  final bool departmentSelectionEnabled; // cho phép NV/QL chọn bộ phận khi đăng ký ca
  final List<StoreWifi> wifis;
  final String status;
  final List<String> memberOrder;
  final List<String> hiddenScheduleUserIds;
  final StorePerformanceStandards performanceStandards;
  final List<EndSessionCriterionModel> endSessionCriteria;

  bool get isDeleted => status == 'deleted';

  const StoreModel({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    this.address,
    this.networkIP,
    this.latitude,
    this.longitude,
    this.radiusMeters = 100,
    this.locations = const [],
    required this.createdAt,
    this.customShifts = const [],
    this.departments = const [],
    this.deliveryAllowance,
    this.giaoHangAllowance,
    this.deliveryEnabled = true,
    this.giaoHangEnabled = true,
    this.themeColor,
    this.departmentSelectionEnabled = true,
    this.wifis = const [],
    this.status = 'active',
    this.memberOrder = const [],
    this.hiddenScheduleUserIds = const [],
    this.performanceStandards = const StorePerformanceStandards(),
    this.endSessionCriteria = const [],
  });

  factory StoreModel.fromJson(Map<String, dynamic> json, String id) {
    final legacyIp = json['networkIP'] as String?;
    final rawWifis = (json['wifis'] as List<dynamic>?)
            ?.map((e) => StoreWifi.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Auto-migration: if legacy networkIP exists and is not yet in wifis list, include it
    final resolvedWifis = List<StoreWifi>.from(rawWifis);
    if (legacyIp != null && legacyIp.trim().isNotEmpty) {
      if (!resolvedWifis.any((w) => w.ip.trim() == legacyIp.trim())) {
        resolvedWifis.insert(
          0,
          StoreWifi(
            name: 'WiFi Chính',
            ip: legacyIp.trim(),
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    final rawLocations = (json['locations'] as List<dynamic>?)
            ?.map((e) => StoreLocation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final legacyLat = (json['latitude'] as num?)?.toDouble();
    final legacyLng = (json['longitude'] as num?)?.toDouble();
    final legacyRadius = (json['radiusMeters'] as int?) ?? 100;

    final resolvedLocations = List<StoreLocation>.from(rawLocations);
    if (resolvedLocations.isEmpty && legacyLat != null && legacyLng != null) {
      resolvedLocations.add(
        StoreLocation(
          id: 'loc_primary',
          name: 'Vị trí chính',
          latitude: legacyLat,
          longitude: legacyLng,
          radiusMeters: legacyRadius,
        ),
      );
    }

    return StoreModel(
      id: id,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      address: json['address'] as String?,
      networkIP: legacyIp,
      latitude: resolvedLocations.isNotEmpty
          ? resolvedLocations.first.latitude
          : legacyLat,
      longitude: resolvedLocations.isNotEmpty
          ? resolvedLocations.first.longitude
          : legacyLng,
      radiusMeters: resolvedLocations.isNotEmpty
          ? resolvedLocations.first.radiusMeters
          : legacyRadius,
      locations: resolvedLocations,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate().toUtc()
          : DateTime.tryParse(json['createdAt'] as String? ?? '') ??
              DateTime.now().toUtc(),
      customShifts: (json['customShifts'] as List<dynamic>?)
              ?.map((e) => ShiftDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      departments: (json['departments'] as List<dynamic>?)
              ?.map((e) => DepartmentDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryAllowance: json['deliveryAllowance'] as num?,
      giaoHangAllowance: json['giaoHangAllowance'] as num?,
      deliveryEnabled: json['deliveryEnabled'] as bool? ?? true,
      giaoHangEnabled: json['giaoHangEnabled'] as bool? ?? true,
      themeColor: json['themeColor'] as String?,
      departmentSelectionEnabled: json['departmentSelectionEnabled'] as bool? ?? true,
      wifis: resolvedWifis,
      status: json['status'] as String? ?? 'active',
      memberOrder: (json['memberOrder'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      hiddenScheduleUserIds: (json['hiddenScheduleUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      performanceStandards: StorePerformanceStandards.fromJson(
        json['performanceStandards'] as Map<String, dynamic>?,
      ),
      endSessionCriteria: (json['endSessionCriteria'] as List<dynamic>?)
              ?.map((e) => EndSessionCriterionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreModel.fromJson(data, doc.id);
  }

  Map<String, dynamic> toJson() {
    final primaryLoc = locations.isNotEmpty ? locations.first : null;
    return {
      'name': name,
      'code': code,
      'ownerId': ownerId,
      'address': address,
      'networkIP': networkIP,
      'latitude': primaryLoc?.latitude ?? latitude,
      'longitude': primaryLoc?.longitude ?? longitude,
      'radiusMeters': primaryLoc?.radiusMeters ?? radiusMeters,
      'locations': locations.map((l) => l.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'customShifts': customShifts.map((s) => s.toJson()).toList(),
      'departments': departments.map((d) => d.toJson()).toList(),
      'deliveryAllowance': deliveryAllowance,
      'giaoHangAllowance': giaoHangAllowance,
      'deliveryEnabled': deliveryEnabled,
      'giaoHangEnabled': giaoHangEnabled,
      'themeColor': themeColor,
      'departmentSelectionEnabled': departmentSelectionEnabled,
      'wifis': wifis.map((w) => w.toJson()).toList(),
      'status': status,
      'memberOrder': memberOrder,
      'hiddenScheduleUserIds': hiddenScheduleUserIds,
      'performanceStandards': performanceStandards.toJson(),
      'endSessionCriteria': endSessionCriteria.map((c) => c.toJson()).toList(),
    };
  }

  StoreModel copyWith({
    String? id,
    String? name,
    String? code,
    String? ownerId,
    String? address,
    String? networkIP,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    List<StoreLocation>? locations,
    DateTime? createdAt,
    List<ShiftDefinition>? customShifts,
    List<DepartmentDefinition>? departments,
    num? deliveryAllowance,
    num? giaoHangAllowance,
    bool? deliveryEnabled,
    bool? giaoHangEnabled,
    String? themeColor,
    bool? departmentSelectionEnabled,
    List<StoreWifi>? wifis,
    String? status,
    List<String>? memberOrder,
    List<String>? hiddenScheduleUserIds,
    StorePerformanceStandards? performanceStandards,
    List<EndSessionCriterionModel>? endSessionCriteria,
    bool clearAddress = false,
    bool clearNetworkIP = false,
    bool clearLocation = false,
    bool clearLocations = false,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      ownerId: ownerId ?? this.ownerId,
      address: clearAddress ? null : (address ?? this.address),
      networkIP: clearNetworkIP ? null : (networkIP ?? this.networkIP),
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      radiusMeters: radiusMeters ?? this.radiusMeters,
      locations: clearLocations ? const [] : (locations ?? this.locations),
      createdAt: createdAt ?? this.createdAt,
      customShifts: customShifts ?? this.customShifts,
      departments: departments ?? this.departments,
      deliveryAllowance: deliveryAllowance ?? this.deliveryAllowance,
      giaoHangAllowance: giaoHangAllowance ?? this.giaoHangAllowance,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      giaoHangEnabled: giaoHangEnabled ?? this.giaoHangEnabled,
      themeColor: themeColor ?? this.themeColor,
      departmentSelectionEnabled: departmentSelectionEnabled ?? this.departmentSelectionEnabled,
      wifis: wifis ?? this.wifis,
      status: status ?? this.status,
      memberOrder: memberOrder ?? this.memberOrder,
      hiddenScheduleUserIds: hiddenScheduleUserIds ?? this.hiddenScheduleUserIds,
      performanceStandards: performanceStandards ?? this.performanceStandards,
      endSessionCriteria: endSessionCriteria ?? this.endSessionCriteria,
    );
  }

  bool get hasLocation => locations.isNotEmpty || (latitude != null && longitude != null);
  bool get hasWifi => (networkIP != null && networkIP!.isNotEmpty) || wifis.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        ownerId,
        address,
        networkIP,
        latitude,
        longitude,
        radiusMeters,
        locations,
        createdAt,
        customShifts,
        departments,
        deliveryAllowance,
        giaoHangAllowance,
        deliveryEnabled,
        giaoHangEnabled,
        themeColor,
        departmentSelectionEnabled,
        wifis,
        status,
        memberOrder,
        hiddenScheduleUserIds,
        performanceStandards,
        endSessionCriteria,
      ];

  @override
  String toString() =>
      'StoreModel(id: $id, name: $name, code: $code, ownerId: $ownerId, status: $status)';
}
