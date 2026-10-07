class EvidenceItemModel {
  final int id;
  final int? sopPhotoPointId;
  final int? pointUrutan;
  final String pointNama;
  final String fileName;
  final String fileUrl;
  final String? apiFileUrl;
  final String tipeItem;
  final String? capturedAt;
  final bool isTambahan;

  EvidenceItemModel({
    required this.id,
    this.sopPhotoPointId,
    this.pointUrutan,
    required this.pointNama,
    required this.fileName,
    required this.fileUrl,
    this.apiFileUrl,
    this.tipeItem = 'foto',
    this.capturedAt,
    this.isTambahan = false,
  });

  factory EvidenceItemModel.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
    
    // Extract point info from direct keys or nested relation
    int? urutan = json['point_urutan'] is int
        ? json['point_urutan']
        : int.tryParse(json['point_urutan']?.toString() ?? '');
    String? nama = json['point_nama']?.toString() ?? json['nama_titik']?.toString();

    if (json['sop_photo_point'] is Map) {
      urutan ??= json['sop_photo_point']['urutan'] is int
          ? json['sop_photo_point']['urutan']
          : int.tryParse(json['sop_photo_point']['urutan']?.toString() ?? '');
      nama ??= json['sop_photo_point']['nama_titik']?.toString();
    }

    // Resolve robust URL
    String fUrl = json['file_url']?.toString() ?? json['url']?.toString() ?? '';
    final filePath = json['file_path']?.toString() ?? '';
    if (fUrl.isEmpty && filePath.isNotEmpty) {
      fUrl = 'http://localhost/spv-track/web/public/storage/$filePath';
    }

    String? apiFUrl = json['api_file_url']?.toString();
    if ((apiFUrl == null || apiFUrl.isEmpty) && idVal > 0) {
      apiFUrl = 'http://localhost/spv-track/web/public/api/evidence/$idVal/file';
    }

    return EvidenceItemModel(
      id: idVal,
      sopPhotoPointId: json['sop_photo_point_id'] is int
          ? json['sop_photo_point_id']
          : int.tryParse(json['sop_photo_point_id']?.toString() ?? ''),
      pointUrutan: urutan,
      pointNama: nama ?? (urutan != null ? 'Titik $urutan' : 'Bukti Foto'),
      fileName: json['file_name']?.toString() ?? '',
      fileUrl: fUrl,
      apiFileUrl: apiFUrl,
      tipeItem: json['tipe_item']?.toString() ?? 'foto',
      capturedAt: json['captured_at']?.toString(),
      isTambahan: json['is_tambahan'] == true || json['is_tambahan'] == 1,
    );
  }
}


class ShipmentModel {
  final int id;
  final String packingListNo;
  final String shipmentGroup;
  final String shipmentNo;
  final String platNomor;
  final String nomorContainerAtauPlat;
  final String? namaSopir;
  final String jenisProduk; // fiber / sodium
  final String jenisPengiriman; // export / lokal
  final String cuaca; // kering / mendung / hujan / gerimis
  final String waktu; // siang / sore / malam
  final String warehouseLokasi; // atas / tengah / bawah
  final String? tanggalStaging;
  final String? waktuKedatangan;
  final String? waktuKeberangkatan;
  final String? tujuanPengiriman;
  final String? agenForwarding;
  final String status; // draft / submitted
  final String? petugasNama;
  final int evidenceCount;
  final String? createdAt;
  final List<EvidenceItemModel> evidenceItems;

  ShipmentModel({
    required this.id,
    required this.packingListNo,
    required this.shipmentGroup,
    required this.shipmentNo,
    required this.platNomor,
    required this.nomorContainerAtauPlat,
    this.namaSopir,
    required this.jenisProduk,
    required this.jenisPengiriman,
    required this.cuaca,
    required this.waktu,
    required this.warehouseLokasi,
    this.tanggalStaging,
    this.waktuKedatangan,
    this.waktuKeberangkatan,
    this.tujuanPengiriman,
    this.agenForwarding,
    required this.status,
    this.petugasNama,
    this.evidenceCount = 0,
    this.createdAt,
    this.evidenceItems = const [],
  });

  bool get isSubmitted => status.toLowerCase() == 'submitted';

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['evidence_items'] ?? json['evidenceItems'];
    List<EvidenceItemModel> items = [];
    if (rawItems is List) {
      items = rawItems.map((e) => EvidenceItemModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    String? petNama = json['petugas_nama']?.toString();
    if (petNama == null && json['karyawan'] is Map) {
      petNama = json['karyawan']['nama']?.toString();
    }

    final idVal = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
    String plNo = json['packing_list_no']?.toString() ?? '';
    String contNo = json['nomor_container_atau_plat']?.toString() ?? '';
    if (plNo.isEmpty && contNo.isEmpty) {
      contNo = 'SPV-$idVal';
    }

    return ShipmentModel(
      id: idVal,
      packingListNo: plNo,
      shipmentGroup: json['shipment_group']?.toString() ?? '',
      shipmentNo: json['shipment_no']?.toString() ?? '',
      platNomor: json['plat_nomor']?.toString() ?? '',
      nomorContainerAtauPlat: contNo,
      namaSopir: json['nama_sopir']?.toString(),
      jenisProduk: json['jenis_produk']?.toString() ?? 'fiber',
      jenisPengiriman: json['jenis_pengiriman']?.toString() ?? 'export',
      cuaca: json['cuaca']?.toString() ?? 'kering',
      waktu: json['waktu']?.toString() ?? 'siang',
      warehouseLokasi: json['warehouse_lokasi']?.toString() ?? 'atas',
      tanggalStaging: json['tanggal_staging']?.toString(),
      waktuKedatangan: json['waktu_kedatangan_container']?.toString(),
      waktuKeberangkatan: json['waktu_keberangkatan_container']?.toString(),
      tujuanPengiriman: json['tujuan_pengiriman']?.toString(),
      agenForwarding: json['agen_forwarding']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      petugasNama: petNama,
      evidenceCount: json['evidence_count'] is int
          ? json['evidence_count']
          : (items.isNotEmpty ? items.length : ((json['evidence_items'] as List?)?.length ?? 0)),
      createdAt: json['created_at']?.toString(),
      evidenceItems: items,
    );

  }
}
