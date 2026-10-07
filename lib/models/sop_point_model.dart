class SopPointModel {
  final int id;
  final int urutan;
  final String namaTitik;
  final String deskripsi;
  final String tipeItem; // 'foto' or 'video'
  final bool wajib;
  final bool perluOcrContainer;
  final bool perluDeteksiOrang;
  final bool perluDeteksiBarcode;

  SopPointModel({
    required this.id,
    required this.urutan,
    required this.namaTitik,
    required this.deskripsi,
    this.tipeItem = 'foto',
    this.wajib = true,
    this.perluOcrContainer = false,
    this.perluDeteksiOrang = false,
    this.perluDeteksiBarcode = false,
  });

  factory SopPointModel.fromJson(Map<String, dynamic> json) {
    return SopPointModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      urutan: json['urutan'] is int ? json['urutan'] : int.tryParse(json['urutan'].toString()) ?? 0,
      namaTitik: json['nama_titik']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString() ?? '',
      tipeItem: json['tipe_item']?.toString() ?? 'foto',
      wajib: json['wajib'] == true || json['wajib'] == 1 || json['wajib'] == '1',
      perluOcrContainer: json['perlu_ocr_container'] == true || json['perlu_ocr_container'] == 1,
      perluDeteksiOrang: json['perlu_deteksi_orang'] == true || json['perlu_deteksi_orang'] == 1,
      perluDeteksiBarcode: json['perlu_deteksi_barcode'] == true || json['perlu_deteksi_barcode'] == 1,
    );
  }

  // 27 Standard Points definition as per SPV-Track specification
  static List<SopPointModel> get defaultPoints => [
    SopPointModel(id: 1, urutan: 1, namaTitik: 'Plat Nomor', deskripsi: 'Foto plat nomor truck/container', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 2, urutan: 2, namaTitik: 'Foto di Loading Area', deskripsi: 'Photo Fiber/Sodium di loading/staging area yang sudah dikumpulkan', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 3, urutan: 3, namaTitik: 'Foto Bales (Zoomable)', deskripsi: 'Photo Fiber/Sodium di loading/staging area, nomor bales terbaca saat di-zoom', tipeItem: 'foto', wajib: true, perluDeteksiBarcode: true),
    SopPointModel(id: 4, urutan: 4, namaTitik: 'Pembersihan Bagian Depan', deskripsi: 'Photo Fiber/Sodium bagian depan sedang dibersihkan', tipeItem: 'foto', wajib: true, perluDeteksiOrang: true),
    SopPointModel(id: 5, urutan: 5, namaTitik: 'Pembersihan Bagian Samping', deskripsi: 'Photo Fiber/Sodium bagian samping sedang dibersihkan', tipeItem: 'foto', wajib: true, perluDeteksiOrang: true),
    SopPointModel(id: 6, urutan: 6, namaTitik: 'Pembersihan Bagian Atas', deskripsi: 'Photo Fiber/Sodium bagian atas sedang dibersihkan', tipeItem: 'foto', wajib: true, perluDeteksiOrang: true),
    SopPointModel(id: 7, urutan: 7, namaTitik: 'Container Luar Kiri', deskripsi: 'Photo container bagian luar sisi kiri, nomor container terbaca', tipeItem: 'foto', wajib: true, perluOcrContainer: true),
    SopPointModel(id: 8, urutan: 8, namaTitik: 'Container Luar Kanan', deskripsi: 'Photo container bagian luar sisi kanan dari arah depan container', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 9, urutan: 9, namaTitik: 'Lantai Container Kosong', deskripsi: 'Photo lantai container dalam keadaan kosong (wajib ada terpal untuk non woven)', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 10, urutan: 10, namaTitik: 'Bagian Atas Dalam', deskripsi: 'Photo bagian atas dalam container', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 11, urutan: 11, namaTitik: 'Bagian Kanan Dalam', deskripsi: 'Photo bagian kanan dalam container, nomor container harus terbaca', tipeItem: 'foto', wajib: true, perluOcrContainer: true),
    SopPointModel(id: 12, urutan: 12, namaTitik: 'Bagian Kiri Dalam', deskripsi: 'Photo bagian kiri dalam container', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 13, urutan: 13, namaTitik: 'Swab Test Dinding Kiri', deskripsi: 'Photo swab test permukaan dinding kiri menggunakan majun', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 14, urutan: 14, namaTitik: 'Swab Test Dinding Kanan', deskripsi: 'Photo swab test permukaan dinding kanan menggunakan majun', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 15, urutan: 15, namaTitik: 'Swab Test Dinding Depan', deskripsi: 'Photo swab test permukaan dinding depan menggunakan majun', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 16, urutan: 16, namaTitik: 'Terisi Baris Pertama', deskripsi: 'Photo terisi fiber/bales baris pertama', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 17, urutan: 17, namaTitik: 'Terisi Setengah Container', deskripsi: 'Photo terisi fiber/bales setengah container', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 18, urutan: 18, namaTitik: 'Terisi Penuh dan Tersegel', deskripsi: 'Photo terisi fiber/bales penuh dan tersegel', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 19, urutan: 19, namaTitik: 'Tertutup Satu Pintu', deskripsi: 'Photo tertutup satu pintu, nomor container harus terbaca', tipeItem: 'foto', wajib: true, perluOcrContainer: true),
    SopPointModel(id: 20, urutan: 20, namaTitik: 'Container Terkunci', deskripsi: 'Photo container tertutup dan terkunci', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 21, urutan: 21, namaTitik: 'Pintu Tertutup Tampak Segel', deskripsi: 'Photo pintu tertutup tampak segel, nomor container, plat nomor, pelayaran', tipeItem: 'foto', wajib: true, perluOcrContainer: true),
    SopPointModel(id: 22, urutan: 22, namaTitik: 'Foto Segel', deskripsi: 'Foto detail segel container/truk', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 23, urutan: 23, namaTitik: 'Ban Diganjal Stopper', deskripsi: 'Photo 2 ban diganjal stopper keamanan', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 24, urutan: 24, namaTitik: 'Checklist Container / Truck', deskripsi: 'Truck Checklist (Lokal) / Container Checklist (Export)', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 25, urutan: 25, namaTitik: 'Bales Inspection Ball', deskripsi: 'Foto inspeksi kebersihan dan fisik bale', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 26, urutan: 26, namaTitik: 'Surat Jalan + Scan OK', deskripsi: 'Surat Jalan + scan stempel "OK"', tipeItem: 'foto', wajib: true),
    SopPointModel(id: 27, urutan: 27, namaTitik: 'Video Singkat', deskripsi: 'Video singkat bukti kelayakan container & muatan', tipeItem: 'video', wajib: false),
  ];
}
