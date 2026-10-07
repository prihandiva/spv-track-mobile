import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _urlCtrl = TextEditingController();

  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final url = await _api.getBaseUrl();
    if (!mounted) return;
    setState(() => _urlCtrl.text = url);
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    await _api.setBaseUrl(_urlCtrl.text.trim());
    final res = await _api.checkServerConnection();

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testSuccess = res['online'] == true;
      if (_testSuccess) {
        final timeData = res['data'];
        _testResult = 'Berhasil terhubung ke database! Waktu Server: ${timeData?['time'] ?? "OK"} ${timeData?['timezone'] ?? "WIB"}';
      } else {
        _testResult = 'Gagal terhubung (${res['error'] ?? "Koneksi terputus"}).';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Pengaturan & Koneksi',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KONEKSI BACKEND LARAVEL
            Container(
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandAzure.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.dns_rounded, color: AppColors.brandAzure, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Konfigurasi Backend Server',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textHeading),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tentukan alamat endpoint Laravel (Laragon Apache / Localhost / IP LAN) agar sinkronisasi data live berjalan otomatis.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _urlCtrl,
                    style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      labelText: 'Base URL Endpoint Server',
                      prefixIcon: Icon(Icons.link_rounded, size: 18, color: AppColors.brandAzure),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Preset chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: Text('Laragon Default', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
                        avatar: const Icon(Icons.check_circle_outline, size: 14, color: AppColors.brandAzure),
                        onPressed: () => setState(() => _urlCtrl.text = 'http://localhost/spv-track/web/public'),
                      ),
                      ActionChip(
                        label: Text('Port 8000', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: () => setState(() => _urlCtrl.text = 'http://localhost:8000'),
                      ),
                      ActionChip(
                        label: Text('Emulator Android', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: () => setState(() => _urlCtrl.text = 'http://10.0.2.2/spv-track/web/public'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_testResult != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _testSuccess ? AppColors.statusSubmittedBg : AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _testSuccess ? AppColors.statusSubmittedBorder : AppColors.errorBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _testSuccess ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                            color: _testSuccess ? AppColors.statusSubmitted : AppColors.errorRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _testResult!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: _testSuccess ? AppColors.statusSubmitted : AppColors.errorRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        _isTesting ? 'Menguji Koneksi...' : 'Simpan & Uji Koneksi Live Database',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandAzure,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. INFORMASI SISTEM & SOP
            Container(
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandTealLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_rounded, color: AppColors.brandTealLight, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Informasi Sistem SPV-Track',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textHeading),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildAboutRow('Instansi Resmi', 'PT. South Pacific Viscose'),
                  _buildAboutRow('Departemen', 'Warehouse & Logistik (Staging Area)'),
                  _buildAboutRow('Standar Kepatuhan', 'SOP 27 Titik Pemeriksaan Kontainer & Truk'),
                  _buildAboutRow('Versi Aplikasi', '1.0.0 (Production Flutter Mobile)'),
                  _buildAboutRow('Backend Integration', 'Laravel 11 REST API & PostgreSQL'),
                  _buildAboutRow('Integritas Bukti', 'Append-Only & Immutable (No Data Deletion)'),
                ],
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textHeading, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
