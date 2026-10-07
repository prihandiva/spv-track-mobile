import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../models/karyawan_model.dart';
import 'timeline_screen.dart';

class FieldAppCreateScreen extends StatefulWidget {
  const FieldAppCreateScreen({super.key});

  @override
  State<FieldAppCreateScreen> createState() => _FieldAppCreateScreenState();
}

class _FieldAppCreateScreenState extends State<FieldAppCreateScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _packingListCtrl = TextEditingController();
  final _shipmentGroupCtrl = TextEditingController();
  final _shipmentNoCtrl = TextEditingController();
  final _platNomorCtrl = TextEditingController();
  final _containerCtrl = TextEditingController();
  final _namaSopirCtrl = TextEditingController();

  // Selections
  String _jenisProduk = 'fiber'; // fiber / sodium
  String _jenisPengiriman = 'export'; // export / lokal
  String _cuaca = 'kering'; // kering, mendung, hujan, gerimis
  String _waktu = 'siang'; // siang, sore, malam
  String _warehouseLokasi = 'atas'; // atas, tengah, bawah
  DateTime _tanggalStaging = DateTime.now();

  // Karyawan / Petugas
  List<KaryawanModel> _allKaryawans = [];
  final List<int> _selectedKaryawanIds = [];
  bool _isLoadingKaryawans = true;

  // OCR Document State
  Uint8List? _ocrBytes;
  bool _isOcrRunning = false;
  String? _ocrSummary;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadKaryawans();
  }

  Future<void> _loadKaryawans() async {
    final list = await _api.getKaryawans();
    if (!mounted) return;
    setState(() {
      _allKaryawans = list;
      _isLoadingKaryawans = false;
      if (list.isNotEmpty && _selectedKaryawanIds.isEmpty) {
        _selectedKaryawanIds.add(list.first.id);
      }
    });
  }

  Future<void> _scanShipmentOrderDoc() async {
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
                'Upload / Ambil Dokumen SO',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Sistem OCR akan mendeteksi 5 data utama secara otomatis',
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
                title: Text('Gunakan Kamera', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                onTap: () async {
                  final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (ctx.mounted) Navigator.pop(ctx, img);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentEmeraldDark.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.accentEmeraldDark, size: 20),
                ),
                title: Text('Pilih dari Galeri', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                onTap: () async {
                  final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (ctx.mounted) Navigator.pop(ctx, img);
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _ocrBytes = bytes;
      _isOcrRunning = true;
      _ocrSummary = null;
    });

    try {
      final res = await _api.ocrShipmentOrder(picked);
      if (!mounted) return;
      setState(() {
        _isOcrRunning = false;
        if (res['success'] == true) {
          if (res['packing_list_no']?.isNotEmpty == true) {
            _packingListCtrl.text = res['packing_list_no'];
          }
          if (res['shipment_group']?.isNotEmpty == true) {
            _shipmentGroupCtrl.text = res['shipment_group'];
          }
          if (res['shipment_no']?.isNotEmpty == true) {
            _shipmentNoCtrl.text = res['shipment_no'];
          }
          if (res['plat_nomor']?.isNotEmpty == true) {
            _platNomorCtrl.text = res['plat_nomor'];
          }
          if (res['container_no']?.isNotEmpty == true) {
            _containerCtrl.text = res['container_no'];
          }
          if (res['nama_sopir']?.isNotEmpty == true) {
            _namaSopirCtrl.text = res['nama_sopir'];
          }
          _ocrSummary = 'Data berhasil diekstrak via OCR Tesseract!';
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data dari Shipment Order berhasil diekstrak!'),
            backgroundColor: AppColors.statusSubmitted,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isOcrRunning = false;
        _ocrSummary = 'Gagal membaca OCR otomatis. Silakan lengkapi manual.';
      });
    }
  }

  void _submitDraft() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi formulir sesuai ketentuan'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_selectedKaryawanIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 orang Petugas Lapangan'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'jenis_produk': _jenisProduk,
        'jenis_pengiriman': _jenisPengiriman,
        'packing_list_no': _packingListCtrl.text.trim(),
        'shipment_group': _shipmentGroupCtrl.text.trim(),
        'shipment_no': _shipmentNoCtrl.text.trim(),
        'plat_nomor': _platNomorCtrl.text.trim(),
        'nomor_container_atau_plat': _containerCtrl.text.trim(),
        'nama_sopir': _namaSopirCtrl.text.trim().isEmpty ? '-' : _namaSopirCtrl.text.trim(),
        'cuaca': _cuaca,
        'waktu': _waktu,
        'warehouse_lokasi': _warehouseLokasi,
        'tanggal_staging': DateFormat('yyyy-MM-dd').format(_tanggalStaging),
        'karyawan_ids': _selectedKaryawanIds,
      };

      final created = await _api.createShipment(payload);

      setState(() => _isSubmitting = false);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TimelineScreen(shipment: created)),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Mulai Staging Baru',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textHeading, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textHeading),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. OCR CARD BANNER
              _buildOcrCard(),

              const SizedBox(height: 18),

              // 2. KATEGORI UTAMA (PRODUK & PENGIRIMAN)
              _buildCategorySelectors(),

              const SizedBox(height: 18),

              // 3. NOMOR IDENTIFIER (9 DIGIT)
              _buildIdentifierFields(),

              const SizedBox(height: 18),

              // 4. KENDARAAN & SOPIR
              _buildVehicleFields(),

              const SizedBox(height: 18),

              // 5. KONDISI LAPANGAN
              _buildOperationalConditionFields(),

              const SizedBox(height: 18),

              // 6. PETUGAS LAPANGAN
              _buildPetugasField(),

              const SizedBox(height: 26),

              // 7. SUBMIT BUTTON
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.cardHeaderGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.elevateShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDraft,
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
                        Flexible(
                          child: Text(
                            'Lanjut ke Timeline Evidence (27 Titik)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOcrCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF93C5FD)),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.cardHeaderGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Shipment Order (Opsional)',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textHeading),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Auto-fill 5 data utama secara cepat & akurat',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_ocrBytes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(_ocrBytes!, height: 110, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          if (_ocrSummary != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statusSubmittedBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusSubmittedBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.statusSubmitted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ocrSummary!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.statusSubmitted, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isOcrRunning ? null : _scanShipmentOrderDoc,
              icon: _isOcrRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt_rounded, size: 18),
              label: Text(_isOcrRunning ? 'Membaca Teks OCR...' : 'Scan / Ambil Dokumen SO'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandAzure,
                side: const BorderSide(color: AppColors.brandAzure, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelectors() {
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
            '1. Kategori & Alur Pengiriman',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textHeading),
          ),
          const SizedBox(height: 14),
          Text(
            'Jenis Produk',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  label: 'FIBER',
                  selected: _jenisProduk == 'fiber',
                  onTap: () => setState(() => _jenisProduk = 'fiber'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceChip(
                  label: 'SODIUM',
                  selected: _jenisProduk == 'sodium',
                  onTap: () => setState(() => _jenisProduk = 'sodium'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Jenis Pengiriman',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  label: 'EXPORT (Container)',
                  selected: _jenisPengiriman == 'export',
                  onTap: () => setState(() => _jenisPengiriman = 'export'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceChip(
                  label: 'LOKAL (Trucking)',
                  selected: _jenisPengiriman == 'lokal',
                  onTap: () => setState(() => _jenisPengiriman = 'lokal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brandAzure : AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(12),
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
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildIdentifierFields() {
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
            '2. Nomor Identifikasi Staging (Format 9 Digit Angka)',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textHeading),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _packingListCtrl,
            keyboardType: TextInputType.number,
            maxLength: 9,
            style: GoogleFonts.spaceMono(fontWeight: FontWeight.w700, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'No. Surat Jalan / Delivery / Packing List *',
              hintText: 'Contoh: 800123456',
              prefixIcon: Icon(Icons.receipt_rounded, size: 18, color: AppColors.brandAzure),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Wajib diisi';
              if (v.trim().length != 9 || int.tryParse(v.trim()) == null) return 'Harus tepat 9 digit angka';
              return null;
            },
          ),
          const SizedBox(height: 6),

          TextFormField(
            controller: _shipmentGroupCtrl,
            keyboardType: TextInputType.number,
            maxLength: 9,
            style: GoogleFonts.spaceMono(fontWeight: FontWeight.w700, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Nomor Shipment Group *',
              hintText: 'Contoh: 869026487',
              prefixIcon: Icon(Icons.grid_view_rounded, size: 18, color: AppColors.brandAzure),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Wajib diisi';
              if (v.trim().length != 9 || int.tryParse(v.trim()) == null) return 'Harus tepat 9 digit angka';
              return null;
            },
          ),
          const SizedBox(height: 6),

          TextFormField(
            controller: _shipmentNoCtrl,
            keyboardType: TextInputType.number,
            maxLength: 9,
            style: GoogleFonts.spaceMono(fontWeight: FontWeight.w700, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Nomor Shipment *',
              hintText: 'Contoh: 860110918',
              prefixIcon: Icon(Icons.tag_rounded, size: 18, color: AppColors.brandAzure),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Wajib diisi';
              if (v.trim().length != 9 || int.tryParse(v.trim()) == null) return 'Harus tepat 9 digit angka';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleFields() {
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
            '3. Armada & Petugas Ekspedisi',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textHeading),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _platNomorCtrl,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
            decoration: const InputDecoration(
              labelText: 'Plat Nomor Truk / Kendaraan *',
              hintText: 'Contoh: B 9123 SPV',
              prefixIcon: Icon(Icons.pin_rounded, size: 18, color: AppColors.brandAzure),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Plat nomor wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _containerCtrl,
            style: GoogleFonts.spaceMono(fontWeight: FontWeight.w700, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Nomor Container / Identitas Fisik *',
              hintText: 'Contoh: TGHU1234567 atau Plat Truk',
              prefixIcon: Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.brandAzure),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Nomor container/plat wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _namaSopirCtrl,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Nama Sopir (Opsional)',
              hintText: 'Contoh: Ahmad / Hendra',
              prefixIcon: Icon(Icons.person_pin_rounded, size: 18, color: AppColors.brandAzure),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalConditionFields() {
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
            '4. Kondisi Operasional Staging',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textHeading),
          ),
          const SizedBox(height: 14),

          // Tanggal Staging
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tanggalStaging,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _tanggalStaging = picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.brandAzure),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            DateFormat('dd MMMM yyyy').format(_tanggalStaging),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _waktu,
                  decoration: const InputDecoration(labelText: 'Waktu / Shift'),
                  items: const [
                    DropdownMenuItem(value: 'siang', child: Text('Siang')),
                    DropdownMenuItem(value: 'sore', child: Text('Sore')),
                    DropdownMenuItem(value: 'malam', child: Text('Malam')),
                  ],
                  onChanged: (v) => setState(() => _waktu = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _cuaca,
                  decoration: const InputDecoration(labelText: 'Cuaca'),
                  items: const [
                    DropdownMenuItem(value: 'kering', child: Text('Kering')),
                    DropdownMenuItem(value: 'mendung', child: Text('Mendung')),
                    DropdownMenuItem(value: 'hujan', child: Text('Hujan')),
                    DropdownMenuItem(value: 'gerimis', child: Text('Gerimis')),
                  ],
                  onChanged: (v) => setState(() => _cuaca = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _warehouseLokasi,
            decoration: const InputDecoration(labelText: 'Lokasi Warehouse'),
            items: const [
              DropdownMenuItem(value: 'atas', child: Text('Warehouse Atas')),
              DropdownMenuItem(value: 'tengah', child: Text('Warehouse Tengah')),
              DropdownMenuItem(value: 'bawah', child: Text('Warehouse Bawah')),
            ],
            onChanged: (v) => setState(() => _warehouseLokasi = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildPetugasField() {
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
                '5. Petugas Lapangan *',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textHeading),
              ),
              TextButton.icon(
                onPressed: _showKaryawanSelectorDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'Pilih Petugas',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandAzure),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingKaryawans)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_selectedKaryawanIds.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.errorBorder),
              ),
              child: Text(
                'Belum ada petugas yang dipilih',
                style: GoogleFonts.plusJakartaSans(color: AppColors.errorRed, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allKaryawans
                  .where((k) => _selectedKaryawanIds.contains(k.id))
                  .map((k) => Chip(
                        backgroundColor: AppColors.brandAzure.withOpacity(0.08),
                        side: BorderSide(color: AppColors.brandAzure.withOpacity(0.2)),
                        avatar: const CircleAvatar(
                          backgroundColor: AppColors.brandAzure,
                          child: Icon(Icons.person_rounded, color: Colors.white, size: 14),
                        ),
                        label: Text(
                          k.nama,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textHeading),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14),
                        onDeleted: () {
                          setState(() => _selectedKaryawanIds.remove(k.id));
                        },
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  void _showKaryawanSelectorDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Pilih Petugas Staging', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allKaryawans.length,
                  itemBuilder: (_, idx) {
                    final k = _allKaryawans[idx];
                    final isChecked = _selectedKaryawanIds.contains(k.id);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text(k.nama, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text(k.nomorInduk, style: GoogleFonts.spaceMono(fontSize: 11)),
                      activeColor: AppColors.brandAzure,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            _selectedKaryawanIds.add(k.id);
                          } else {
                            _selectedKaryawanIds.remove(k.id);
                          }
                        });
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Selesai', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
