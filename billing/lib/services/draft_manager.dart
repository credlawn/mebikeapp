import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DraftManager {
  static const String _draftKey = 'current_partner_draft_data';
  static const String _draftIdKey = 'pending_partner_onboarding_id';

  /// Saves the entire form data locally as a JSON string.
  static Future<void> saveLocalDraft(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(data));
    
    // Also ensure the ID is synced
    if (data.containsKey('id') && data['id'] != null) {
      await prefs.setString(_draftIdKey, data['id']);
    }
  }

  /// Retrieves the locally saved draft data.
  static Future<Map<String, dynamic>?> getLocalDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_draftKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clears the local cache completely.
  static Future<void> clearLocalDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    await prefs.remove(_draftIdKey);
  }

  /// Helper to get only the current Draft ID
  static Future<String?> getDraftId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_draftIdKey);
  }
}
