import '../../../../core/network/api_client.dart';
import '../../domain/entities/secret.dart';
import '../../domain/repositories/vault_repository.dart';

class RemoteVaultRepositoryImpl implements VaultRepository {
  final ApiClient apiClient;

  RemoteVaultRepositoryImpl({required this.apiClient});

  @override
  Future<List<Secret>> getSecrets() async {
    final List<dynamic> data = await apiClient.get('/api/v1/vault/secrets');
    return data.map((json) => Secret.fromJson(json)).toList();
  }

  @override
  Future<Secret> createSecret({
    required String name,
    required String type,
    required String value,
    String? description,
  }) async {
    final data = await apiClient.post('/api/v1/vault/secrets', data: {
      'name': name,
      'type': type,
      'value': value,
      'description': description,
    });
    return Secret.fromJson(data);
  }

  @override
  Future<void> deleteSecret(String name) async {
    await apiClient.delete('/api/v1/vault/secrets/$name');
  }
}
