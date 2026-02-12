import '../entities/cluster_entity.dart';

abstract class DashboardRepository {
  Future<List<ClusterEntity>> getClusters();
}
