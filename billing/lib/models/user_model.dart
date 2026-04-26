import 'package:pocketbase/pocketbase.dart';

class UserModel {
  final String id;
  final String email;
  final String role;
  final bool isEnabled;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.isEnabled,
  });

  static UserModel fromRecord(RecordModel record) {
    return UserModel(
      id: record.id,
      email: record.getStringValue('email'),
      role: record.getStringValue('role'),
      isEnabled: record.getBoolValue('enable'),
    );
  }
}
