import 'package:equatable/equatable.dart';

class Secret extends Equatable {
  final String id;
  final String name;
  final String type;
  final String? description;
  final DateTime? createdAt;

  const Secret({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.createdAt,
  });

  factory Secret.fromJson(Map<String, dynamic> json) {
    return Secret(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  @override
  List<Object?> get props => [id, name, type, description, createdAt];
}
