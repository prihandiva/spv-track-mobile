import 'shipment_model.dart';

class DashboardStatsModel {
  final int totalShipments;
  final int totalSubmitted;
  final int totalDraft;
  final int totalPetugas;
  final double successRate;
  final int todayShipments;
  final int todaySubmitted;
  final int fiberCount;
  final int sodiumCount;
  final int exportCount;
  final int lokalCount;
  final List<ShipmentModel> recentShipments;

  DashboardStatsModel({
    this.totalShipments = 0,
    this.totalSubmitted = 0,
    this.totalDraft = 0,
    this.totalPetugas = 0,
    this.successRate = 0.0,
    this.todayShipments = 0,
    this.todaySubmitted = 0,
    this.fiberCount = 0,
    this.sodiumCount = 0,
    this.exportCount = 0,
    this.lokalCount = 0,
    this.recentShipments = const [],
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    var rawRecent = json['recent_shipments'];
    List<ShipmentModel> recents = [];
    if (rawRecent is List) {
      recents = rawRecent.map((e) => ShipmentModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    var jenisProduk = json['jenis_produk'] as Map<String, dynamic>? ?? {};
    var jenisPengiriman = json['jenis_pengiriman'] as Map<String, dynamic>? ?? {};

    return DashboardStatsModel(
      totalShipments: json['total_shipments'] ?? 0,
      totalSubmitted: json['total_submitted'] ?? 0,
      totalDraft: json['total_draft'] ?? 0,
      totalPetugas: json['total_petugas'] ?? 0,
      successRate: (json['success_rate'] is num) ? (json['success_rate'] as num).toDouble() : 0.0,
      todayShipments: json['today_shipments'] ?? 0,
      todaySubmitted: json['today_submitted'] ?? 0,
      fiberCount: jenisProduk['fiber'] ?? 0,
      sodiumCount: jenisProduk['sodium'] ?? 0,
      exportCount: jenisPengiriman['export'] ?? 0,
      lokalCount: jenisPengiriman['lokal'] ?? 0,
      recentShipments: recents,
    );
  }
}
