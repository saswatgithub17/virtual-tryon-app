// lib/models/user_model.dart
// User/Customer Data Model

class User {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final DateTime? createdAt;

  User({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }

  // Create empty user
  factory User.empty() {
    return User(
      userId: '',
      name: '',
      email: '',
    );
  }

  // Copy with
  User copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) {
    return User(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      createdAt: createdAt,
    );
  }

  bool get hasAddress => address != null && address!.isNotEmpty;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasCompleteAddress =>
      hasAddress && city != null && state != null && pincode != null;
}

// Admin Model
class Admin {
  final int adminId;
  final String username;
  final String email;
  final String? name;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  Admin({
    required this.adminId,
    required this.username,
    required this.email,
    this.name,
    this.role = 'admin',
    this.isActive = true,
    this.createdAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      adminId: json['admin_id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      role: json['role'] ?? 'admin',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admin_id': adminId,
      'username': username,
      'email': email,
      'name': name,
      'role': role,
      'is_active': isActive,
    };
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get canManageDresses => isActive;
  bool get canManageOrders => isActive;
}

// Auth Session
class AuthSession {
  final String token;
  final User? user;
  final Admin? admin;
  final DateTime expiresAt;
  final bool isAdmin;

  AuthSession({
    required this.token,
    this.user,
    this.admin,
    required this.expiresAt,
    this.isAdmin = false,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      admin: json['admin'] != null ? Admin.fromJson(json['admin']) : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(days: 7)),
      isAdmin: json['is_admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user?.toJson(),
      'admin': admin?.toJson(),
      'expires_at': expiresAt.toIso8601String(),
      'is_admin': isAdmin,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired && token.isNotEmpty;

  String get displayName {
    if (isAdmin && admin != null) {
      return admin!.name ?? admin!.username;
    }
    if (user != null) {
      return user!.name;
    }
    return 'Guest';
  }
}