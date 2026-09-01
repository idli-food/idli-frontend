// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileHash() => r'1711db68ecbd27a43352cfd589c5c452a2d3b61c';

/// See also [profile].
@ProviderFor(profile)
final profileProvider = AutoDisposeFutureProvider<UserProfile>.internal(
  profile,
  name: r'profileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRef = AutoDisposeFutureProviderRef<UserProfile>;
String _$completeProfileNotifierHash() =>
    r'663d70064aecc5209b8ce33bfb519a7ce229c743';

/// See also [CompleteProfileNotifier].
@ProviderFor(CompleteProfileNotifier)
final completeProfileNotifierProvider =
    AutoDisposeNotifierProvider<
      CompleteProfileNotifier,
      ProfileUpdateState
    >.internal(
      CompleteProfileNotifier.new,
      name: r'completeProfileNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$completeProfileNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CompleteProfileNotifier = AutoDisposeNotifier<ProfileUpdateState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
