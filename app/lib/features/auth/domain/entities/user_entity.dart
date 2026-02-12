import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final List<String> permissions;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.permissions,
  });

  @override
  List<Object> get props => [id, username, email, permissions];
}
