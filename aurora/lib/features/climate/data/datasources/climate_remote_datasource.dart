/// Datasource remoto para Climate Analytics.
library;

import '../../../../core/network/api_client.dart';

class ClimateRemoteDataSource {
  final ApiClient _apiClient;

  ClimateRemoteDataSource(this._apiClient);

  /// Registra una nueva lectura manual.
  Future<Map<String, dynamic>> addReading(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/api/v1/climate/reading',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Obtiene los datos actuales del cultivo.
  Future<Map<String, dynamic>> getCurrent(String growId) async {
    final response = await _apiClient.get('/api/v1/climate/current/$growId');
    return response.data as Map<String, dynamic>;
  }

  /// Obtiene el historial por período (days).
  Future<Map<String, dynamic>> getHistory(String growId, {int days = 7}) async {
    final response = await _apiClient.get(
      '/api/v1/climate/history/$growId',
      queryParameters: {'days': days},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Obtiene análisis IA.
  Future<Map<String, dynamic>> getAnalysis(String growId) async {
    final response = await _apiClient.get('/api/v1/climate/analysis/$growId');
    return response.data as Map<String, dynamic>;
  }
}
