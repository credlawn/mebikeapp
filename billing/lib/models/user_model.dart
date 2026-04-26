import 'package:pocketbase/pocketbase.dart';

class UserModel {
  final String id;
  final String email;
  final String role;
  final bool isEnabled;
  final bool forcePasswordChange;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.isEnabled,
    required this.forcePasswordChange,
  });

  static UserModel fromRecord(RecordModel record) {
    return UserModel(
      id: record.id,
      email: record.getStringValue('email'),
      role: record.getStringValue('role'),
      isEnabled: record.getBoolValue('enable'),
      forcePasswordChange: record.getBoolValue('force_password_change'),
    );
  }
}
