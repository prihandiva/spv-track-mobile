import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../models/shipment_model.dart';
import '../../models/sop_point_model.dart';

class TimelineScreen extends StatefulWidget {
  final ShipmentModel shipment;
  const TimelineScreen({super.key, required this.shipment});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  late ShipmentModel _currentShipment;
  List<SopPointModel> _sopPoints = [];
  bool _isLoading = true;

  // Local map of uploaded files per point ID: pointId -> File / url
  final Map<int, String> _uploadedPhotoPaths = {};
  final Map<int, String> _uploadedTimestamps = {};
  final List<String> _extraPhotos = [];

  // Start & End Staging times
  DateTime? _waktuKedatangan;
  DateTime? _waktuKeberangkatan;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentShipment = widget.shipment;
    _loadPointsAndDetails();
  }

  Future<void> _loadPointsAndDetails() async {
    setState(() => _isLoading = true);
    final points = await _api.getSopPoints();
    final fresh = await _api.getShipmentDetail(_currentShipment.id);

    // Map existing evidence items
    for (var ev in fresh.evidenceItems) {
      if (ev.sopPhotoPointId != null) {
        _uploadedPhotoPaths[ev.sopPhotoPointId!] = ev.fileUrl;
        _uploadedTimestamps[ev.sopPhotoPointId!] = ev.capturedAt ?? '';
      } else if (ev.isTambahan) {
        _extraPhotos.add(ev.fileUrl);
      }
    }

    if (fresh.waktuKedatangan != null) {
      try {
        _waktuKedatangan = DateTime.parse(fresh.waktuKedatangan!);
      } catch (_) {}
    }
    if (fresh.waktuKeberangkatan != null) {
      try {
        _waktuKeberangkatan = DateTime.parse(fresh.waktuKeberangkatan!);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _sopPoints = points;
      _currentShipment = fresh;
      _isLoading = false;
    });
  }

  int get _mandatoryUploadedCount {
    int count = 0;
    for (var pt in _sopPoints) {
      if (pt.wajib && _uploadedPhotoPaths.containsKey(pt.id)) {
        count++;
      }
    }
    return count;
  }

  int get _totalMandatoryCount {
    return _sopPoints.where((p) => p.wajib).length;
  }

  bool get _canSubmit {
    return _mandatoryUploadedCount >= _totalMandatoryCount &&
        _waktuKedatangan != null &&
        _waktuKeberangkatan != null;
  }

  Future<void> _capturePointPhoto(SopPointModel point) async {
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Titik ${point.urutan}: ${point.namaTitik}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                point.deskripsi,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandAzure.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.brandAzure, size: 20),
                ),
                title: Text('Ambil Foto Kamera (WIB Timestamp)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                onTap: () async {
                  final img = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, img);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandTealLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.brandTealLight, size: 20),
                ),
                title: Text('Pilih dari Galeri Foto', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                onTap: () async {
                  final img = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, img);
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (picked == null) return;

    final timestampFormatted = '${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())} WIB';

    setState(() {
      _uploadedPhotoPaths[point.id] = picked.path;
      _uploadedTimestamps[point.id] = timestampFormatted;
    });

    _api.uploadEvidence(
      shipmentId: _currentShipment.id,
      pointId: point.id,
      file: picked,
    ).then((res) {
      if (mounted && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto Titik ${point.urutan} tersimpan dengan cap waktu server!'),
            backgroundColor: AppColors.statusSubmitted,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _addExtraPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) {
      setState(() => _extraPhotos.add(picked.path));
      _api.uploadEvidence(
        shipmentId: _currentShipment.id,
        file: picked,
        isTambahan: true,
      );
    }
  }

  Future<void> _submitFinal() async {
    if (!_canSubmit) {
      final missingCount = _totalMandatoryCount - _mandatoryUploadedCount;
      String msg = '';
      if (missingCount > 0) {
        msg += '$missingCount foto SOP wajib belum diambil. ';
      }
      if (_waktuKedatangan == null) {
        msg += 'Waktu mulai kedatangan belum diisi. ';
      }
      if (_waktuKeberangkatan == null) {
        msg += 'Waktu akhir keberangkatan belum diisi. ';
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.accentAmberDark),
              const SizedBox(width: 8),
              Text('Data Belum Lengkap', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Text(msg.trim(), style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Konfirmasi Submit Final', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(
          'Seluruh bukti foto evidence 27 titik SOP akan disimpan secara permanen (immutable) ke database PT. South Pacific Viscose. Lanjutkan?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentEmeraldDark),
            child: Text('Ya, Submit Final', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'waktu_kedatangan_container': _waktuKedatangan!.toIso8601String(),
        'waktu_keberangkatan_container': _waktuKeberangkatan!.toIso8601String(),
        'packing_list_no': _currentShipment.packingListNo,
      };

      await _api.finalizeShipment(_currentShipment.id, payload);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.statusSubmittedBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.statusSubmitted, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Staging Berhasil Disimpan!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Evidence untuk ${_currentShipment.packingListNo} telah lengkap dan tervalidasi secara permanen.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAzure,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Kembali ke Dashboard', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Timeline Evidence 27 Titik SOP',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textHeading, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textHeading),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandAzure, strokeWidth: 3))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SHIPMENT HEADER CARD
                  _buildShipmentHeaderCard(),

                  const SizedBox(height: 16),

                  // 2. PROGRESS STATS
                  _buildProgressStats(),

                  const SizedBox(height: 14),

                  // 3. HORIZONTAL CAMERA ADVISORY BANNER
                  _buildCameraAdvisoryBanner(),

                  const SizedBox(height: 20),

                  // 4. STEP CARDS (27 TITIK SOP)
                  Text(
                    'Daftar 27 Titik Bukti SOP',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textHeading),
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sopPoints.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final point = _sopPoints[idx];
                      return _buildSopPointCard(point);
                    },
                  ),

                  const SizedBox(height: 18),

                  // 5. EXTRA PHOTOS BUTTON
                  _buildExtraPhotosSection(),

                  const SizedBox(height: 20),

                  // 6. WAKTU KEDATANGAN & KEBERANGKATAN
                  _buildStagingTimesSection(),

                  const SizedBox(height: 26),

                  // 7. FINAL SUBMIT BUTTON
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _canSubmit ? AppColors.emeraldGradient : AppColors.cardHeaderGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.elevateShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFinal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSubmitting)
                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          else ...[
                            const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Submit Final Evidence Staging',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }

  Widget _buildShipmentHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardHeaderGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.elevateShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'NO. SURAT JALAN / PACKING LIST',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(
                      _currentShipment.status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentShipment.packingListNo.isNotEmpty ? _currentShipment.packingListNo : _currentShipment.nomorContainerAtauPlat,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceMono(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 5,
            children: [
              _buildWhiteMeta('Group', _currentShipment.shipmentGroup),
              _buildWhiteMeta('Shpt', _currentShipment.shipmentNo),
              _buildWhiteMeta('Plat', _currentShipment.platNomor),
              _buildWhiteMeta('Cont', _currentShipment.nomorContainerAtauPlat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteMeta(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: ', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11)),
          TextSpan(
            text: value.isNotEmpty ? value : '-',
            style: GoogleFonts.spaceMono(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStats() {
    return Row(
      children: [
        Expanded(
          child: _buildProgressBox('Titik Total', '${_sopPoints.length}', AppColors.brandAzure),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildProgressBox('Terupload', '${_uploadedPhotoPaths.length}', AppColors.accentEmeraldDark),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildProgressBox(
            'Wajib Selesai',
            '$_mandatoryUploadedCount / $_totalMandatoryCount',
            _mandatoryUploadedCount >= _totalMandatoryCount ? AppColors.statusSubmitted : AppColors.statusDraft,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBox(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCameraAdvisoryBanner() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandAzure.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.screen_rotation_rounded, color: AppColors.brandAzure, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rekomendasi: Ambil foto secara Horizontal / Landscape agar detail barcode & nomor kontainer terbaca jelas.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.brandAzure, height: 1.35, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSopPointCard(SopPointModel point) {
    final isUploaded = _uploadedPhotoPaths.containsKey(point.id);
    final filePath = _uploadedPhotoPaths[point.id];
    final timestamp = _uploadedTimestamps[point.id];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUploaded ? AppColors.accentEmerald.withOpacity(0.5) : AppColors.border,
          width: isUploaded ? 1.5 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isUploaded ? AppColors.statusSubmittedBg : AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUploaded ? AppColors.statusSubmitted : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${point.urutan}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: isUploaded ? AppColors.statusSubmitted : AppColors.textHeading,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            point.namaTitik,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textHeading),
                          ),
                        ),
                        if (point.wajib)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'WAJIB',
                              style: GoogleFonts.plusJakartaSans(color: AppColors.errorRed, fontSize: 9.5, fontWeight: FontWeight.w800),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'OPSIONAL',
                              style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 9.5, fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point.deskripsi,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (isUploaded && filePath != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      if (filePath.startsWith('http') || filePath.startsWith('blob:') || kIsWeb)
                        Image.network(
                          filePath,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 130,
                            color: Colors.grey.shade100,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        )
                      else
                        Image.file(
                          File(filePath),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            timestamp ?? 'Cap Waktu Tersimpan',
                            style: GoogleFonts.spaceMono(color: AppColors.accentEmerald, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.statusSubmitted, size: 17),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Tersimpan & Terverifikasi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(color: AppColors.statusSubmitted, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _capturePointPhoto(point),
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: Text(
                        'Ambil Ulang',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _capturePointPhoto(point),
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: Text(
                  point.tipeItem == 'video' ? 'Ambil Video Bukti' : 'Ambil Foto Titik ${point.urutan}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.scaffoldBg,
                  foregroundColor: AppColors.brandAzure,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExtraPhotosSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Foto Tambahan / Ekstra',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textHeading),
              ),
              TextButton.icon(
                onPressed: _addExtraPhoto,
                icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                label: Text(
                  'Tambah Foto',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandAzure),
                ),
              ),
            ],
          ),
          if (_extraPhotos.isEmpty)
            Text(
              'Tidak ada foto ekstra di luar 27 titik standar.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
            )
          else
            SizedBox(
              height: 85,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _extraPhotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, idx) {
                  final p = _extraPhotos[idx];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (p.startsWith('http') || p.startsWith('blob:') || kIsWeb)
                        ? Image.network(p, width: 85, height: 85, fit: BoxFit.cover)
                        : Image.file(File(p), width: 85, height: 85, fit: BoxFit.cover),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStagingTimesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waktu Operasional Staging *',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textHeading),
          ),
          const SizedBox(height: 14),

          _buildTimeRow(
            label: 'Waktu Mulai (Kedatangan Container)',
            time: _waktuKedatangan,
            onSetNow: () => setState(() => _waktuKedatangan = DateTime.now()),
            onPick: () async {
              final pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2030));
              if (pickedDate != null && mounted) {
                final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (pickedTime != null) {
                  setState(() {
                    _waktuKedatangan = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                  });
                }
              }
            },
          ),

          const SizedBox(height: 16),

          _buildTimeRow(
            label: 'Waktu Selesai (Keberangkatan Container)',
            time: _waktuKeberangkatan,
            onSetNow: () => setState(() => _waktuKeberangkatan = DateTime.now()),
            onPick: () async {
              final pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2030));
              if (pickedDate != null && mounted) {
                final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (pickedTime != null) {
                  setState(() {
                    _waktuKeberangkatan = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow({
    required String label,
    required DateTime? time,
    required VoidCallback onSetNow,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    time != null ? DateFormat('dd MMM yyyy, HH:mm').format(time) : 'Pilih tanggal & jam...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: time != null
                        ? GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textHeading)
                        : GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textLight),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onSetNow,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandAzure,
                side: const BorderSide(color: AppColors.brandAzure),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Sekarang',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
