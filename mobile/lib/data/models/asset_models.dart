class ImportError {
  final int row;
  final String message;

  const ImportError({required this.row, required this.message});

  factory ImportError.fromJson(Map<String, dynamic> json) => ImportError(
        row: json['row'] as int,
        message: json['message'] as String,
      );
}

class ImportResultModel {
  final int created;
  final int skipped;
  final List<ImportError> errors;

  const ImportResultModel({
    required this.created,
    required this.skipped,
    required this.errors,
  });

  factory ImportResultModel.fromJson(Map<String, dynamic> json) =>
      ImportResultModel(
        created: json['created'] as int,
        skipped: json['skipped'] as int,
        errors: (json['errors'] as List<dynamic>)
            .map((e) => ImportError.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CreateAssetRequest {
  final String inventoryNumber;
  final String name;
  final String? barcode;
  final String? description;

  const CreateAssetRequest({
    required this.inventoryNumber,
    required this.name,
    this.barcode,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'inventory_number': inventoryNumber,
        'name': name,
        if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
        if (description != null && description!.isNotEmpty)
          'description': description,
      };
}

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
