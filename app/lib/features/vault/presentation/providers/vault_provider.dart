import 'package:flutter/material.dart';
import '../../domain/entities/secret.dart';
import '../../domain/repositories/vault_repository.dart';

class VaultProvider with ChangeNotifier {
  final VaultRepository repository;
  
  List<Secret> _secrets = [];
  bool _isLoading = false;
  String? _error;

  VaultProvider({required this.repository}) {
    fetchSecrets();
  }

  List<Secret> get secrets => _secrets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSecrets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _secrets = await repository.getSecrets();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSecret({
    required String name,
    required String type,
    required String value,
    String? description,
  }) async {
    try {
      await repository.createSecret(
        name: name,
        type: type,
        value: value,
        description: description,
      );
      await fetchSecrets();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSecret(String name) async {
    try {
      await repository.deleteSecret(name);
      await fetchSecrets();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
