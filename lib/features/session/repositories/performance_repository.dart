import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/performance_session_model.dart';
import '../../../models/measurement_model.dart';
import '../../../models/performance_report_model.dart';

class PerformanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection('performance_sessions');

  CollectionReference<Map<String, dynamic>> get _reportsCol =>
      _firestore.collection('performance_reports');

  CollectionReference<Map<String, dynamic>> _measurementsCol(String sessionId) =>
      _sessionsCol.doc(sessionId).collection('measurements');

  // ---------- SESSIONS ----------

  Future<void> createSession(PerformanceSessionModel session) async {
    await _sessionsCol.doc(session.id).set(session.toJson());
  }

  Stream<PerformanceSessionModel?> watchActiveSession(String storeId) {
    return _sessionsCol
        .where('storeId', isEqualTo: storeId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return PerformanceSessionModel.fromFirestore(snap.docs.first);
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

  Future<void> addSessionIncident(String sessionId, PerformanceIncidentModel incident) async {
    await _sessionsCol.doc(sessionId).update({
      'incidents': FieldValue.arrayUnion([incident.toJson()]),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> removeSessionIncident(String sessionId, PerformanceIncidentModel incident) async {
    await _sessionsCol.doc(sessionId).update({
      'incidents': FieldValue.arrayRemove([incident.toJson()]),
      'updatedAt': Timestamp.now(),
    });
  }

  // ---------- MEASUREMENTS ----------

  Stream<List<MeasurementModel>> watchMeasurements(String sessionId) {
    return _measurementsCol(sessionId).snapshots().map((snap) {
      final list = snap.docs.map((doc) => MeasurementModel.fromFirestore(doc)).toList();
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

  Stream<List<PerformanceReportModel>> watchAllReports() {
    return _reportsCol.snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => PerformanceReportModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
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

  Stream<int> watchAllUnviewedReportsCount() {
    return _reportsCol
        .where('status', isEqualTo: ReportStatus.submitted.value)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
