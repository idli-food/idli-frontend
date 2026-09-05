import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/feed_post.dart';
import '../services/post_service.dart';

part 'instant_feed_provider.g.dart';

@riverpod
Future<List<FeedPost>> instantFeed(InstantFeedRef ref) async {
  return PostService().getInstantFeed();
}
