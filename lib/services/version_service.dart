import 'api_service.dart';

/// Checks the backend's advertised latest mobile version. Never throws -
/// a failed check should not block or error out the app, it just means no
/// update notice is shown.
class VersionService {
  final ApiService _api = ApiService();

  Future<String?> getLatestMobileVersion() async {
    try {
      final response = await _api.get('/');
      return response.data['latestMobileVersion'] as String?;
    } catch (e) {
      return null;
    }
  }
}
