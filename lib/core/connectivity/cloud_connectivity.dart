import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_connectivity.g.dart';

@riverpod
Stream<bool> hasNetwork(HasNetworkRef ref) async* {
  final connectivity = Connectivity();
  bool connected(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
  yield connected(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(connected).distinct();
}
