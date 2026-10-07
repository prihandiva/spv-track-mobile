import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../models/shipment_model.dart';
import '../field_app/field_app_create_screen.dart';
import 'shipment_detail_screen.dart';

class ShipmentsListScreen extends StatefulWidget {
  const ShipmentsListScreen({super.key});

  @override
  State<ShipmentsListScreen> createState() => _ShipmentsListScreenState();
}

class _ShipmentsListScreenState extends State<ShipmentsListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<ShipmentModel> _shipments = [];
  bool _isLoading = true;

  String _filterType = 'semua'; // semua, export, lokal
  String _filterStatus = 'semua'; // semua, submitted, draft

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final list = await _api.getShipments(
      search: _searchCtrl.text.trim(),
      type: _filterType,
      status: _filterStatus,
    );
    if (!mounted) return;
    setState(() {
      _shipments = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Daftar Staging & Evidence',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textHeading,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textHeading),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardHeaderGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandBlue.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FieldAppCreateScreen()),
            ).then((_) => _fetchData());
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 19),
          label: Text(
            'Mulai Staging',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR & DYNAMIC FILTERS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _fetchData(),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Cari packing list, kontainer, plat...',
                    hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textLight, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.brandAzure),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _fetchData();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: AppColors.scaffoldBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filters Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua Jenis', 'semua', _filterType, (v) {
                        setState(() => _filterType = v);
                        _fetchData();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('Export', 'export', _filterType, (v) {
                        setState(() => _filterType = v);
                        _fetchData();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('Lokal', 'lokal', _filterType, (v) {
                        setState(() => _filterType = v);
                        _fetchData();
                      }),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 20, color: AppColors.border),
                      const SizedBox(width: 10),
                      _buildFilterChip('Semua Status', 'semua', _filterStatus, (v) {
                        setState(() => _filterStatus = v);
                        _fetchData();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('Submitted', 'submitted', _filterStatus, (v) {
                        setState(() => _filterStatus = v);
                        _fetchData();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('Draft', 'draft', _filterStatus, (v) {
                        setState(() => _filterStatus = v);
                        _fetchData();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. LIST CONTENT
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandAzure, strokeWidth: 3))
                : _shipments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textLight),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada data staging yang cocok',
                              style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                _searchCtrl.clear();
                                _filterType = 'semua';
                                _filterStatus = 'semua';
                                _fetchData();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Reset Pencarian'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        color: AppColors.brandAzure,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
                          itemCount: _shipments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, idx) {
                            final item = _shipments[idx];
                            return _buildCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current, Function(String) onSelect) {
    final selected = current == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandAzure : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.brandAzure : AppColors.border),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.brandAzure.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: selected ? Colors.white : AppColors.textBody,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ShipmentModel item) {
    final isSubmitted = item.isSubmitted;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
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
            ).then((_) => _fetchData());
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Code + Status Badge
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
                            child: const Icon(Icons.receipt_rounded, size: 16, color: AppColors.brandAzure),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.packingListNo.isNotEmpty ? item.packingListNo : item.nomorContainerAtauPlat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceMono(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
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
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                          Icon(
                            isSubmitted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                            size: 11,
                            color: isSubmitted ? AppColors.statusSubmitted : AppColors.statusDraft,
                          ),
                          const SizedBox(width: 4),
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
                    _buildTag(item.jenisProduk.toUpperCase(), AppColors.brandAzure),
                    _buildTag(item.jenisPengiriman.toUpperCase(), AppColors.brandTealLight),
                    if (item.platNomor.isNotEmpty)
                      _buildTag(item.platNomor, AppColors.textBody),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer Row: Officer & Photo Count
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
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.photo_library_rounded, size: 12, color: AppColors.brandAzure),
                            const SizedBox(width: 4),
                            Text(
                              '${item.evidenceCount} Titik Bukti',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandAzure,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildTag(String text, Color color) {
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
