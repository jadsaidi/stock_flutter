import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/db_service.dart';
import 'auth_provider.dart';

final dbServiceProvider = Provider<DBService?>((ref) {
  final userModel = ref.watch(userModelProvider).value;
  if (userModel != null) {
    return DBService(clientId: userModel.clientId);
  }
  return null;
});
