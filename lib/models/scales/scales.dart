const String scales_id = "id_balanca";
const String scales_state = "estado_balanca";
const String scales_hash = "hash_balanca";

class ScaleModel {
  final int id;
  final String hash;
  final int status;

  ScaleModel({required this.id, required this.hash, required this.status});

  static ScaleModel fromJson(Map<String, dynamic> json) => ScaleModel(
    id: json[scales_id] as int,
    hash: json[scales_hash] as String,
    status: json[scales_state] as int,
  );

  Map<String, dynamic> toJson() => {
    scales_id: id,
    scales_hash: hash,
    scales_state: status,
  };

  ScaleModel copyWith({int? id, String? hash, int? status}) => ScaleModel(
    id: id ?? this.id,
    hash: hash ?? this.hash,
    status: status ?? this.status,
  );
}