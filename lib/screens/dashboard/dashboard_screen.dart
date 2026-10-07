import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../models/dashboard_stats_model.dart';
import '../../models/shipment_model.dart';
import '../field_app/field_app_create_screen.dart';
import '../shipments/shipment_detail_screen.dart';
import '../shipments/shipments_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  DashboardStatsModel _stats = DashboardStatsModel();
  bool _isLoading = true;
  String? _serverStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await _api.getDashboardStats();
    final conn = await _api.checkServerConnection();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _isLoading = false;
      _serverStatus = conn['online'] == true ? 'Live Database • WIB' : 'Mode Offline';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandAzure, strokeWidth: 3),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.brandAzure,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. EXECUTIVE WELCOME BANNER
                    _buildWelcomeBanner(),

                    const SizedBox(height: 18),

                    // 2. KPI METRICS CARDS
                    _buildKpiMetricsGrid(),

                    const SizedBox(height: 20),

                    // 3. STATISTIK OPERASIONAL
                    _buildDistributionSection(),

                    const SizedBox(height: 22),

                    // 4. DAFTAR STAGING TERBARU
                    _buildRecentShipmentsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.executiveGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.elevateShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background subtle ambient light orbs
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentEmerald.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            left: 80,
            bottom: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandAzure.withOpacity(0.18),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badge Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.accentEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _serverStatus ?? 'Live Database',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.accentEmerald,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.corporate_fare_rounded, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'PT. South Pacific Viscose',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  'Sistem Evidence SPV-Track',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Monitoring kepatuhan 27 titik foto SOP staging warehouse & armada logistik secara digital dan real-time.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.emeraldGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentEmeraldDark.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FieldAppCreateScreen()),
                              ).then((_) => _loadData());
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_rounded, size: 17, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mulai Staging',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (widget.onTabChange != null) {
                                widget.onTabChange!(2);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ShipmentsListScreen()),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 17, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Semua Data',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'TOTAL STAGING',
                value: '${_stats.totalShipments}',
                icon: Icons.local_shipping_rounded,
                accentColor: AppColors.brandAzure,
                subtitle: 'Database Aktif',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'SUBMITTED',
                value: '${_stats.totalSubmitted}',
                icon: Icons.check_circle_rounded,
                accentColor: AppColors.accentEmeraldDark,
                subtitle: '${_stats.successRate.toStringAsFixed(0)}% Kepatuhan SOP',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'DRAFT PROSES',
                value: '${_stats.totalDraft}',
                icon: Icons.pending_actions_rounded,
                accentColor: AppColors.accentAmberDark,
                subtitle: 'Menunggu submit',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'PETUGAS AKTIF',
                value: '${_stats.totalPetugas}',
                icon: Icons.badge_rounded,
                accentColor: AppColors.brandNavy,
                subtitle: 'Tim Warehouse',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textHeading,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textLight,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection() {
    final fiberPct = _stats.totalShipments > 0 ? (_stats.fiberCount / _stats.totalShipments * 100).round() : 0;
    final exportPct = _stats.totalShipments > 0 ? (_stats.exportCount / _stats.totalShipments * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandAzure.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_rounded, size: 17, color: AppColors.brandAzure),
              ),
              const SizedBox(width: 10),
              Text(
                'Distribusi Operasional Warehouse',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textHeading,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Kolom Jenis Produk
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jenis Produk',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPillMetric('Fiber', '${_stats.fiberCount}', '$fiberPct%', AppColors.brandAzure),
                    const SizedBox(height: 6),
                    _buildPillMetric('Sodium', '${_stats.sodiumCount}', '${100 - fiberPct}%', AppColors.brandTealLight),
                  ],
                ),
              ),
              Container(width: 1, height: 75, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 14)),
              // Kolom Jenis Pengiriman
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jenis Pengiriman',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPillMetric('Export', '${_stats.exportCount}', '$exportPct%', AppColors.accentEmeraldDark),
                    const SizedBox(height: 6),
                    _buildPillMetric('Lokal', '${_stats.lokalCount}', '${100 - exportPct}%', AppColors.accentAmberDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillMetric(String label, String count, String pct, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textBody, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(width: 3),
          Text(
            '($pct)',
            style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textLight, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentShipmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Staging Terbaru (Database)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textHeading,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                if (widget.onTabChange != null) {
                  widget.onTabChange!(2);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ShipmentsListScreen()));
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brandAzure),
              label: Text(
                'Lihat Semua',
                style: GoogleFonts.plusJakartaSans(color: AppColors.brandAzure, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_stats.recentShipments.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.inbox_outlined, size: 40, color: AppColors.textLight),
                const SizedBox(height: 8),
                Text(
                  'Belum ada data staging di database',
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stats.recentShipments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _stats.recentShipments[index];
              return _buildShipmentCard(item);
            },
          ),
      ],
    );
  }

  Widget _buildShipmentCard(ShipmentModel item) {
    final isSubmitted = item.isSubmitted;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShipmentDetailScreen(shipmentId: item.id)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Code Identifier + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.brandAzure.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.brandAzure),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.packingListNo.isNotEmpty ? item.packingListNo : item.nomorContainerAtauPlat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceMono(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textHeading,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isSubmitted ? AppColors.statusSubmittedBg : AppColors.statusDraftBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSubmitted ? AppColors.statusSubmittedBorder : AppColors.statusDraftBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSubmitted ? AppColors.statusSubmitted : AppColors.statusDraft,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isSubmitted ? 'Submitted' : 'Draft',
                            style: GoogleFonts.plusJakartaSans(
                              color: isSubmitted ? AppColors.statusSubmitted : AppColors.statusDraft,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Tags wrap
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildMetaTag(item.jenisProduk.toUpperCase(), AppColors.brandAzure),
                    _buildMetaTag(item.jenisPengiriman.toUpperCase(), AppColors.brandTealLight),
                    if (item.platNomor.isNotEmpty)
                      _buildMetaTag(item.platNomor, AppColors.textBody),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer: Officer and Evidence Count
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                item.petugasNama ?? 'Operator Warehouse',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_rounded, size: 13, color: AppColors.brandAzure),
                          const SizedBox(width: 4),
                          Text(
                            '${item.evidenceCount} Titik Foto',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.brandAzure,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
