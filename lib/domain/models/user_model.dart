class UserModel {
  final String id;
  final String email;
  final String clientId; // Each user belongs to a client, which dictates their database slice

  UserModel({
    required this.id,
    required this.email,
    required this.clientId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      email: map['email'] ?? '',
      clientId: map['clientId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'clientId': clientId,
    };
  }
}
