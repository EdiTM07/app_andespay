/// Modelo del usuario bancario de AndesPay
/// Representa al cliente autenticado con todos sus datos
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? cedula;
  final String? photoUrl;
  final String? phoneNumber;
  final String? pinHash; // PIN cifrado con SHA-256
  final DateTime createdAt;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.cedula,
    this.photoUrl,
    this.phoneNumber,
    this.pinHash,
    required this.createdAt,
    this.isActive = true,
  });

  /// Construye un UserModel desde un documento de Firestore
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      cedula: json['cedula'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      pinHash: json['pinHash'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Serializa el UserModel para guardarlo en Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'cedula': cedula,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'pinHash': pinHash,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Crea una copia del modelo con campos actualizados
  UserModel copyWith({
    String? fullName,
    String? email,
    String? cedula,
    String? photoUrl,
    String? phoneNumber,
    String? pinHash,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      cedula: cedula ?? this.cedula,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pinHash: pinHash ?? this.pinHash,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, fullName: $fullName, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
