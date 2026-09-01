import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/feed_post.dart';
import '../providers/location_provider.dart';
import '../services/post_service.dart';

part 'feed_provider.g.dart';

@riverpod
Future<List<FeedPost>> feed(FeedRef ref) async {
  final location = ref.watch(locationNotifierProvider).selected;
  if (location == null) return [];
  return PostService().getFeed(lat: location.latitude, lon: location.longitude);
}
