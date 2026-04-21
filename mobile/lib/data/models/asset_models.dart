class AssetModel {
  final String id;
  final String inventoryNumber;
  final String? barcode;
  final String name;
  final String? description;
  final int? categoryId;
  final int? departmentId;
  final int? roomId;
  final String status;
  final String inventoryStatus;
  final String? oneCId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastScannedAt;

  const AssetModel({
    required this.id,
    required this.inventoryNumber,
    this.barcode,
    required this.name,
    this.description,
    this.categoryId,
    this.departmentId,
    this.roomId,
    required this.status,
    required this.inventoryStatus,
    this.oneCId,
    required this.createdAt,
    required this.updatedAt,
    this.lastScannedAt,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as String,
      inventoryNumber: json['inventory_number'] as String,
      barcode: json['barcode'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as int?,
      departmentId: json['department_id'] as int?,
      roomId: json['room_id'] as int?,
      status: json['status'] as String,
      inventoryStatus: json['inventory_status'] as String,
      oneCId: json['one_c_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastScannedAt: json['last_scanned_at'] != null
          ? DateTime.parse(json['last_scanned_at'] as String)
          : null,
    );
  }
}
