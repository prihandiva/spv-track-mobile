class KaryawanModel {
  final int id;
  final String nama;
  final String nomorInduk;
  final String? jabatan;
  final String status;

  KaryawanModel({
    required this.id,
    required this.nama,
    required this.nomorInduk,
    this.jabatan,
    this.status = 'aktif',
  });

  factory KaryawanModel.fromJson(Map<String, dynamic> json) {
    return KaryawanModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nama: json['nama']?.toString() ?? '',
      nomorInduk: json['nomor_induk']?.toString() ?? json['nik']?.toString() ?? '',
      jabatan: json['jabatan']?.toString(),
      status: json['status']?.toString() ?? 'aktif',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'nomor_induk': nomorInduk,
      'jabatan': jabatan,
      'status': status,
    };
  }
}
