import 'package:equatable/equatable.dart';

/// User Model
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? mobileNumber;
  final String? companyId;
  final String? companyName;
  final String? role;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? profileImage;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.id,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.mobileNumber,
    this.companyId,
    this.companyName,
    this.role,
    this.emailVerified = false,
    required this.createdAt,
    this.lastLogin,
    this.profileImage,
    this.metadata,
  });

  String get fullName => '${firstName ?? ""} ${lastName ?? ""}'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? json['user_name'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      mobileNumber: json['mobileNumber'],
      companyId: json['companyId'],
      companyName: json['companyName'],
      role: json['role'],
      emailVerified: json['emailVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      profileImage: json['profileImage'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'companyId': companyId,
      'companyName': companyName,
      'role': role,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'profileImage': profileImage,
      'metadata': metadata,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? mobileNumber,
    String? companyId,
    String? companyName,
    String? role,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? profileImage,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      profileImage: profileImage ?? this.profileImage,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    username,
    firstName,
    lastName,
    mobileNumber,
    companyId,
    companyName,
    role,
    emailVerified,
    createdAt,
    lastLogin,
    profileImage,
    metadata,
  ];
}
