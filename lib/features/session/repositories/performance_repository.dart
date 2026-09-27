import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/performance_session_model.dart';
import '../../../models/measurement_model.dart';
import '../../../models/performance_report_model.dart';
import '../../../models/schedule_model.dart';

const int firestoreWhereInLimit = 30;

List<List<String>> chunkPerformanceStoreIds(Iterable<String> storeIds) {
  final uniqueIds = <String>[];
  final seen = <String>{};
  for (final rawId in storeIds) {
    final id = rawId.trim();
    if (id.isNotEmpty && seen.add(id)) uniqueIds.add(id);
  }

  return [
    for (var start = 0;
        start < uniqueIds.length;
        start += firestoreWhereInLimit)
      uniqueIds.sublist(
        start,
        (start + firestoreWhereInLimit).clamp(0, uniqueIds.length),
      ),
  ];
}

class PerformanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection('performance_sessions');

  CollectionReference<Map<String, dynamic>> get _reportsCol =>
      _firestore.collection('performance_reports');

  CollectionReference<Map<String, dynamic>> _measurementsCol(
          String sessionId) =>
      _sessionsCol.doc(sessionId).collection('measurements');

  // ---------- SESSIONS ----------

  Future<void> createSession(PerformanceSessionModel session) async {
    await _sessionsCol.doc(session.id).set(session.toJson());
  }

  Stream<PerformanceSessionModel?> watchActiveSession({
    required String storeId,
    required String userId,
  }) {
    return _sessionsCol
        .where('storeId', isEqualTo: storeId)
        .where('managerId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final sessions = snap.docs
          .map((d) => PerformanceSessionModel.fromFirestore(d))
          .where(
              (session) => session.canResume(storeId: storeId, userId: userId))
          .toList();
      if (sessions.isEmpty) return null;
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return sessions.first;
    });
  }

  Stream<PerformanceSessionModel?> watchSession(String sessionId) {
    return _sessionsCol.doc(sessionId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return PerformanceSessionModel.fromFirestore(snap);
    });
  }

  Future<void> updateSessionSummary({
    required String sessionId,
    required int drinkCount,
    required int drinkTotalQuantity,
    required int drinkTotalSeconds,
    required int cakeCount,
    required int cakeTotalQuantity,
    required int cakeTotalSeconds,
    required int orderCount,
    required int orderTotalSeconds,
  }) async {
    await _sessionsCol.doc(sessionId).update({
      'drinkCount': drinkCount,
      'drinkTotalQuantity': drinkTotalQuantity,
      'drinkTotalSeconds': drinkTotalSeconds,
      'cakeCount': cakeCount,
      'cakeTotalQuantity': cakeTotalQuantity,
      'cakeTotalSeconds': cakeTotalSeconds,
      'orderCount': orderCount,
      'orderTotalSeconds': orderTotalSeconds,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> addSessionIncident(
      String sessionId, PerformanceIncidentModel incident) async {
    await _sessionsCol.doc(sessionId).update({
      'incidents': FieldValue.arrayUnion([incident.toJson()]),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> removeSessionIncident(
      String sessionId, PerformanceIncidentModel incident) async {
    await _sessionsCol.doc(sessionId).update({
      'incidents': FieldValue.arrayRemove([incident.toJson()]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ---------- MEASUREMENTS ----------

  Stream<List<MeasurementModel>> watchMeasurements(String sessionId) {
    return _measurementsCol(sessionId).snapshots().map((snap) {
      final list =
          snap.docs.map((doc) => MeasurementModel.fromFirestore(doc)).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Future<void> addMeasurement(MeasurementModel measurement) async {
    await _measurementsCol(measurement.sessionId)
        .doc(measurement.id)
        .set(measurement.toJson());
  }

  Future<void> updateMeasurement(MeasurementModel measurement) async {
    await _measurementsCol(measurement.sessionId)
        .doc(measurement.id)
        .update(measurement.toJson());
  }

  Future<void> cancelMeasurement(String sessionId, String measurementId) async {
    await _measurementsCol(sessionId).doc(measurementId).update({
      'status': MeasurementStatus.cancelled.value,
    });
  }

  Future<void> deleteMeasurement(String sessionId, String measurementId) async {
    await _measurementsCol(sessionId).doc(measurementId).delete();
  }

  // ---------- END SESSION & SUBMIT REPORT ----------

  Future<void> endAndSubmitSession({
    required PerformanceSessionModel session,
    required PerformanceReportModel report,
  }) async {
    final batch = _firestore.batch();

    // 1. Update session to completed
    final sessionRef = _sessionsCol.doc(session.id);
    batch.update(sessionRef, {
      'status': SessionStatus.completed.value,
      'endedAt': Timestamp.fromDate(report.endedAt),
      'drinkCount': report.drinkMeasurementCount,
      'drinkTotalQuantity': report.drinkTotalQuantity,
      'drinkTotalSeconds': report.drinkTotalSeconds,
      'cakeCount': report.cakeMeasurementCount,
      'cakeTotalQuantity': report.cakeTotalQuantity,
      'cakeTotalSeconds': report.cakeTotalSeconds,
      'orderCount': report.orderCount,
      'orderTotalSeconds': report.orderTotalSeconds,
      'updatedAt': Timestamp.now(),
    });

    // 2. Create submitted report
    final reportRef = _reportsCol.doc(report.id);
    batch.set(reportRef, report.toJson());

    await batch.commit();
  }

  // ---------- REPORTS ----------

  Stream<List<PerformanceReportModel>> watchReportsForStore(String storeId) {
    return _reportsCol
        .where('storeId', isEqualTo: storeId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => PerformanceReportModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<PerformanceReportModel>> watchReportsForStores(
      List<String> storeIds) {
    final chunks = chunkPerformanceStoreIds(storeIds);
    if (chunks.isEmpty) {
      return Stream.value([]);
    }

    Stream<List<PerformanceReportModel>> watchChunk(List<String> ids) {
      return _reportsCol.where('storeId', whereIn: ids).snapshots().map(
            (snap) => snap.docs
                .map((doc) => PerformanceReportModel.fromFirestore(doc))
                .toList(),
          );
    }

    if (chunks.length == 1) {
      return watchChunk(chunks.first).map((reports) {
        reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reports;
      });
    }

    late StreamController<List<PerformanceReportModel>> controller;
    final subscriptions = <StreamSubscription<List<PerformanceReportModel>>>[];
    final reportsByChunk = <int, List<PerformanceReportModel>>{};

    void emitCombinedReports() {
      final reportsById = <String, PerformanceReportModel>{};
      for (final reports in reportsByChunk.values) {
        for (final report in reports) {
          reportsById[report.id] = report;
        }
      }
      final combined = reportsById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(combined);
    }

    controller = StreamController<List<PerformanceReportModel>>(
      onListen: () {
        for (var index = 0; index < chunks.length; index++) {
          subscriptions.add(
            watchChunk(chunks[index]).listen(
              (reports) {
                reportsByChunk[index] = reports;
                emitCombinedReports();
              },
              onError: controller.addError,
            ),
          );
        }
      },
      onPause: () {
        for (final subscription in subscriptions) {
          subscription.pause();
        }
      },
      onResume: () {
        for (final subscription in subscriptions) {
          subscription.resume();
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Stream<List<PerformanceReportModel>> watchAllReports(
      [List<String>? fallbackStoreIds]) {
    // Không bao giờ query toàn bộ collection mà không có storeId filter
    // để tránh bị Firestore Security Rules chặn lỗi permission-denied.
    if (fallbackStoreIds != null && fallbackStoreIds.isNotEmpty) {
      return watchReportsForStores(fallbackStoreIds);
    }
    return Stream.value([]);
  }

  Stream<PerformanceReportModel?> watchReport(String reportId) {
    return _reportsCol.doc(reportId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return PerformanceReportModel.fromFirestore(snap);
    });
  }

  Future<void> markReportViewed(String reportId, String ownerUid) async {
    await _reportsCol.doc(reportId).update({
      'status': ReportStatus.viewed.value,
      'viewedAt': Timestamp.now(),
      'viewedBy': ownerUid,
    });
  }

  Stream<int> watchUnviewedReportsCount(String storeId) {
    return _reportsCol
        .where('storeId', isEqualTo: storeId)
        .where('status', isEqualTo: ReportStatus.submitted.value)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> watchUnviewedReportsCountForStores(List<String> storeIds) {
    return watchReportsForStores(storeIds).map(
      (reports) =>
          reports.where((r) => r.status == ReportStatus.submitted).length,
    );
  }

  Stream<int> watchAllUnviewedReportsCount([List<String>? fallbackStoreIds]) {
    // Không bao giờ query toàn bộ collection mà không có storeId filter
    // để tránh bị Firestore Security Rules chặn lỗi permission-denied.
    if (fallbackStoreIds != null && fallbackStoreIds.isNotEmpty) {
      return watchUnviewedReportsCountForStores(fallbackStoreIds);
    }
    return Stream.value(0);
  }

  /// Xóa dữ liệu đo lường (sessions, subcollection measurements, và reports)
  /// Có thể lọc theo storeId và khoảng thời gian (startDate, endDate) hoặc deleteAll = true.
  Future<Map<String, int>> deletePerformanceData({
    required String? storeId,
    DateTime? startDate,
    DateTime? endDate,
    bool deleteAll = false,
  }) async {
    int deletedSessions = 0;
    int deletedMeasurements = 0;
    int deletedReports = 0;

    // 1. Query sessions
    Query<Map<String, dynamic>> sessionQuery = _sessionsCol;
    if (storeId != null && storeId.isNotEmpty && storeId != 'all') {
      sessionQuery = sessionQuery.where('storeId', isEqualTo: storeId);
    }
    final sessionSnap = await sessionQuery.get();

    for (final doc in sessionSnap.docs) {
      final data = doc.data();
      DateTime? sessionDate;
      if (data['startedAt'] is Timestamp) {
        sessionDate = (data['startedAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is Timestamp) {
        sessionDate = (data['createdAt'] as Timestamp).toDate();
      }

      bool shouldDelete = deleteAll;
      if (!deleteAll &&
          sessionDate != null &&
          startDate != null &&
          endDate != null) {
        shouldDelete = sessionDate
                .isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
            sessionDate.isBefore(endDate.add(const Duration(milliseconds: 1)));
      }

      if (shouldDelete) {
        // Delete subcollection measurements
        final mSnap = await doc.reference.collection('measurements').get();
        for (final mDoc in mSnap.docs) {
          await mDoc.reference.delete();
          deletedMeasurements++;
        }
        await doc.reference.delete();
        deletedSessions++;
      }
    }

    // 2. Query reports
    Query<Map<String, dynamic>> reportQuery = _reportsCol;
    if (storeId != null && storeId.isNotEmpty && storeId != 'all') {
      reportQuery = reportQuery.where('storeId', isEqualTo: storeId);
    }
    final reportSnap = await reportQuery.get();

    for (final doc in reportSnap.docs) {
      final data = doc.data();
      DateTime? reportDate;
      if (data['startedAt'] is Timestamp) {
        reportDate = (data['startedAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is Timestamp) {
        reportDate = (data['createdAt'] as Timestamp).toDate();
      }

      bool shouldDelete = deleteAll;
      if (!deleteAll &&
          reportDate != null &&
          startDate != null &&
          endDate != null) {
        shouldDelete = reportDate
                .isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
            reportDate.isBefore(endDate.add(const Duration(milliseconds: 1)));
      }

      if (shouldDelete) {
        await doc.reference.delete();
        deletedReports++;
      }
    }

    return {
      'sessions': deletedSessions,
      'measurements': deletedMeasurements,
      'reports': deletedReports,
    };
  }

  // ---------- SCHEDULES (CHAM CONG READ-ONLY) ----------

  /// Đọc dữ liệu lịch làm việc theo tuần từ Firestore (/stores/{storeId}/schedules/{weekStart})
  Future<ScheduleModel?> getWeekSchedule(
      String storeId, String weekStart) async {
    try {
      final doc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('schedules')
          .doc(weekStart)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return ScheduleModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  /// Theo dõi realtime lịch làm việc theo tuần
  Stream<ScheduleModel?> watchWeekSchedule(String storeId, String weekStart) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('schedules')
        .doc(weekStart)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ScheduleModel.fromFirestore(doc);
    });
  }
}
