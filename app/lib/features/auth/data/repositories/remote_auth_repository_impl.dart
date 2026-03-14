import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/network/api_client.dart';

class RemoteAuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  UserEntity? _currentUser;

  RemoteAuthRepositoryImpl({required this.apiClient});

  @override
  Future<UserEntity> login(String username, String password) async {
    final response = await apiClient.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    
    _currentUser = UserEntity(
      id: response['id'],
      username: response['username'],
      email: response['email'],
      permissions: List<String>.from(response['permissions']),
    );
    
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _currentUser;
  }
}
