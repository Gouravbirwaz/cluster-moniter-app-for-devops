import '../entities/secret.dart';

abstract class VaultRepository {
  Future<List<Secret>> getSecrets();
  Future<Secret> createSecret({
    required String name,
    required String type,
    required String value,
    String? description,
  });
  Future<void> deleteSecret(String name);
}
