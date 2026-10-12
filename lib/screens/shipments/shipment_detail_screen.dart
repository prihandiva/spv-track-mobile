import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../models/shipment_model.dart';
import '../field_app/timeline_screen.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final int shipmentId;
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  final ApiService _api = ApiService();
  ShipmentModel? _shipment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    final s = await _api.getShipmentDetail(widget.shipmentId);
    if (!mounted) return;
    setState(() {
      _shipment = s;
      _isLoading = false;
    });
  }

  void _showPhotoDialog(EvidenceItemModel ev) {
    final targetUrl = ev.fileUrl.isNotEmpty ? ev.fileUrl : (ev.apiFileUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  title: Text(
                    ev.pointNama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  actions: [
                    if (targetUrl.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 20),
                        tooltip: 'Buka di Browser / Tab Baru',
                        onPressed: () async {
                          final uri = Uri.parse(targetUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                  ],
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      ev.fileUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        if (ev.apiFileUrl != null && ev.apiFileUrl!.isNotEmpty) {
                          return Image.network(
                            ev.apiFileUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _buildBrokenPlaceholder(targetUrl),
                          );
                        }
                        return _buildBrokenPlaceholder(targetUrl);
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  color: Colors.black,
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nama File: ${ev.fileName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cap Waktu Server: ${ev.capturedAt ?? "WIB Terverifikasi"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceMono(color: AppColors.accentEmerald, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      if (targetUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(targetUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.download_rounded, size: 14, color: AppColors.brandAzure),
                          label: Text(
                            'Buka File Asli / Download Foto',
                            style: GoogleFonts.plusJakartaSans(color: AppColors.brandAzure, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 24),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
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

  Widget _buildBrokenPlaceholder(String targetUrl) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      color: Colors.grey.shade900,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_rounded, size: 48, color: Colors.white38),
          const SizedBox(height: 8),
          Text(
            'Foto belum termuat di canvas browser.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12),
          ),
          if (targetUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(targetUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_browser_rounded, size: 14),
              label: const Text('Buka Langsung di Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAzure,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.brandAzure, strokeWidth: 3)),
      );
    }

    if (_shipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Staging')),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final s = _shipment!;
    final isSubmitted = s.isSubmitted;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          s.packingListNo.isNotEmpty ? s.packingListNo : s.nomorContainerAtauPlat,
          style: GoogleFonts.spaceMono(color: AppColors.textHeading, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textHeading),
        actions: [
          if (!isSubmitted)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TimelineScreen(shipment: s)),
                  ).then((_) => _fetchDetail());
                },
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('Lanjut Timeline'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAzure,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STATUS & VEHICLE SUMMARY BANNER
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.executiveGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppColors.elevateShadow,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'STATUS VALIDASI EVIDENCE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSubmitted ? AppColors.accentEmerald.withOpacity(0.2) : AppColors.accentAmber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSubmitted ? AppColors.accentEmerald : AppColors.accentAmber,
                          ),
                        ),
                        child: Text(
                          isSubmitted ? 'SUBMITTED (PERMANEN)' : 'DRAFT (PROSES)',
                          style: GoogleFonts.plusJakartaSans(
                            color: isSubmitted ? AppColors.accentEmerald : AppColors.accentAmber,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.nomorContainerAtauPlat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceMono(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plat Nomor: ${s.platNomor.isNotEmpty ? s.platNomor : "-"} • Sopir: ${s.namaSopir ?? "-"}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. SPESIFIKASI STAGING (CARD)
            Container(
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
                  Text(
                    'Parameter Staging & Kendaraan',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textHeading),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow('No. Surat Jalan / PL', s.packingListNo, isCode: true),
                  _buildDetailRow('Shipment Group', s.shipmentGroup, isCode: true),
                  _buildDetailRow('Shipment No', s.shipmentNo, isCode: true),
                  if (s.agenForwarding != null && s.agenForwarding!.isNotEmpty)
                    _buildDetailRow('Agen Forwarding', s.agenForwarding!),
                  if (s.tujuanPengiriman != null && s.tujuanPengiriman!.isNotEmpty)
                    _buildDetailRow('Tujuan Pengiriman', s.tujuanPengiriman!),
                  _buildDetailRow('Jenis Produk', s.jenisProduk.toUpperCase()),
                  _buildDetailRow('Jenis Pengiriman', s.jenisPengiriman.toUpperCase()),
                  _buildDetailRow('Lokasi Warehouse', 'Warehouse ${s.warehouseLokasi.toUpperCase()}'),
                  _buildDetailRow('Cuaca & Shift', '${s.cuaca.toUpperCase()} / Shift ${s.waktu.toUpperCase()}'),
                  _buildDetailRow('Petugas', s.petugasNama ?? 'Operator Warehouse'),
                  if (s.waktuKedatangan != null)
                    _buildDetailRow('Mulai Staging', s.waktuKedatangan!),
                  if (s.waktuKeberangkatan != null)
                    _buildDetailRow('Selesai Staging', s.waktuKeberangkatan!),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 3. EVIDENCE PHOTO GALLERY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Galeri Bukti SOP 27 Titik',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textHeading),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandAzure.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${s.evidenceItems.length} Foto Tersimpan',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.brandAzure,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (s.evidenceItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.no_photography_outlined, size: 44, color: AppColors.textLight),
                    const SizedBox(height: 10),
                    Text(
                      'Belum ada foto evidence yang tersimpan.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                    if (!isSubmitted)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TimelineScreen(shipment: s)),
                            ).then((_) => _fetchDetail());
                          },
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: const Text('Buka Timeline & Ambil Foto SOP'),
                        ),
                      ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.76,
                ),
                itemCount: s.evidenceItems.length,
                itemBuilder: (ctx, idx) {
                  final ev = s.evidenceItems[idx];
                  return _buildEvidenceGridTile(ev);
                },
              ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              textAlign: TextAlign.end,
              style: isCode
                  ? GoogleFonts.spaceMono(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textHeading)
                  : GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textHeading),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceGridTile(EvidenceItemModel ev) {
    return InkWell(
      onTap: () => _showPhotoDialog(ev),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ev.fileUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      if (ev.apiFileUrl != null && ev.apiFileUrl!.isNotEmpty) {
                        return Image.network(
                          ev.apiFileUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                          ),
                        );
                      }
                      return Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_outlined, color: Colors.grey),
                      );
                    },
                  ),
                  if (ev.pointUrutan != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandDark.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          '#${ev.pointUrutan}',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ev.pointNama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textHeading),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ev.capturedAt ?? 'WIB Recorded',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceMono(fontSize: 9.5, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
