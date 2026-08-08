// This is a generated file - do not edit.
//
// Generated from karis_review.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use userDescriptor instead')
const User$json = {
  '1': 'User',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
    {'1': 'refresh_time', '3': 3, '4': 1, '5': 9, '10': 'refreshTime'},
  ],
};

/// Descriptor for `User`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDescriptor = $convert.base64Decode(
    'CgRVc2VyEg4KAmlkGAEgASgJUgJpZBIUCgVlbWFpbBgCIAEoCVIFZW1haWwSIQoMcmVmcmVzaF'
    '90aW1lGAMgASgJUgtyZWZyZXNoVGltZQ==');

@$core.Deprecated('Use cardDescriptor instead')
const Card$json = {
  '1': 'Card',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'deck_id', '3': 2, '4': 1, '5': 9, '10': 'deckId'},
    {'1': 'front', '3': 3, '4': 1, '5': 9, '10': 'front'},
    {'1': 'back', '3': 4, '4': 1, '5': 9, '10': 'back'},
    {'1': 'stage', '3': 5, '4': 1, '5': 5, '10': 'stage'},
    {
      '1': 'consecutive_familiar',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'consecutiveFamiliar'
    },
    {
      '1': 'next_review_date',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nextReviewDate',
      '17': true
    },
    {'1': 'learning_mode', '3': 8, '4': 1, '5': 8, '10': 'learningMode'},
    {
      '1': 'reentry_stage',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'reentryStage',
      '17': true
    },
    {'1': 'learning_step', '3': 10, '4': 1, '5': 5, '10': 'learningStep'},
    {'1': 'review_version', '3': 11, '4': 1, '5': 3, '10': 'reviewVersion'},
    {'1': 'created_at', '3': 12, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'updated_at', '3': 13, '4': 1, '5': 9, '10': 'updatedAt'},
    {
      '1': 'learning_origin',
      '3': 14,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'learningOrigin',
      '17': true
    },
  ],
  '8': [
    {'1': '_next_review_date'},
    {'1': '_reentry_stage'},
    {'1': '_learning_origin'},
  ],
};

/// Descriptor for `Card`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cardDescriptor = $convert.base64Decode(
    'CgRDYXJkEg4KAmlkGAEgASgJUgJpZBIXCgdkZWNrX2lkGAIgASgJUgZkZWNrSWQSFAoFZnJvbn'
    'QYAyABKAlSBWZyb250EhIKBGJhY2sYBCABKAlSBGJhY2sSFAoFc3RhZ2UYBSABKAVSBXN0YWdl'
    'EjEKFGNvbnNlY3V0aXZlX2ZhbWlsaWFyGAYgASgFUhNjb25zZWN1dGl2ZUZhbWlsaWFyEi0KEG'
    '5leHRfcmV2aWV3X2RhdGUYByABKAlIAFIObmV4dFJldmlld0RhdGWIAQESIwoNbGVhcm5pbmdf'
    'bW9kZRgIIAEoCFIMbGVhcm5pbmdNb2RlEigKDXJlZW50cnlfc3RhZ2UYCSABKAlIAVIMcmVlbn'
    'RyeVN0YWdliAEBEiMKDWxlYXJuaW5nX3N0ZXAYCiABKAVSDGxlYXJuaW5nU3RlcBIlCg5yZXZp'
    'ZXdfdmVyc2lvbhgLIAEoA1INcmV2aWV3VmVyc2lvbhIdCgpjcmVhdGVkX2F0GAwgASgJUgljcm'
    'VhdGVkQXQSHQoKdXBkYXRlZF9hdBgNIAEoCVIJdXBkYXRlZEF0EiwKD2xlYXJuaW5nX29yaWdp'
    'bhgOIAEoCUgCUg5sZWFybmluZ09yaWdpbogBAUITChFfbmV4dF9yZXZpZXdfZGF0ZUIQCg5fcm'
    'VlbnRyeV9zdGFnZUISChBfbGVhcm5pbmdfb3JpZ2lu');

@$core.Deprecated('Use deckDescriptor instead')
const Deck$json = {
  '1': 'Deck',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'created_at', '3': 3, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'updated_at', '3': 4, '4': 1, '5': 9, '10': 'updatedAt'},
    {
      '1': 'cards',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.karisreview.Card',
      '10': 'cards'
    },
  ],
};

/// Descriptor for `Deck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deckDescriptor = $convert.base64Decode(
    'CgREZWNrEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEh0KCmNyZWF0ZWRfYX'
    'QYAyABKAlSCWNyZWF0ZWRBdBIdCgp1cGRhdGVkX2F0GAQgASgJUgl1cGRhdGVkQXQSJwoFY2Fy'
    'ZHMYBSADKAsyES5rYXJpc3Jldmlldy5DYXJkUgVjYXJkcw==');

@$core.Deprecated('Use reviewLogDescriptor instead')
const ReviewLog$json = {
  '1': 'ReviewLog',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'card_id', '3': 2, '4': 1, '5': 9, '10': 'cardId'},
    {'1': 'rating', '3': 3, '4': 1, '5': 9, '10': 'rating'},
    {'1': 'stage_before', '3': 4, '4': 1, '5': 5, '10': 'stageBefore'},
    {'1': 'stage_after', '3': 5, '4': 1, '5': 5, '10': 'stageAfter'},
    {'1': 'reviewed_at', '3': 6, '4': 1, '5': 9, '10': 'reviewedAt'},
    {'1': 'is_new_card', '3': 7, '4': 1, '5': 8, '10': 'isNewCard'},
    {
      '1': 'client_request_id',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'clientRequestId',
      '17': true
    },
    {
      '1': 'learning_origin',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'learningOrigin',
      '17': true
    },
  ],
  '8': [
    {'1': '_client_request_id'},
    {'1': '_learning_origin'},
  ],
};

/// Descriptor for `ReviewLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewLogDescriptor = $convert.base64Decode(
    'CglSZXZpZXdMb2cSDgoCaWQYASABKAlSAmlkEhcKB2NhcmRfaWQYAiABKAlSBmNhcmRJZBIWCg'
    'ZyYXRpbmcYAyABKAlSBnJhdGluZxIhCgxzdGFnZV9iZWZvcmUYBCABKAVSC3N0YWdlQmVmb3Jl'
    'Eh8KC3N0YWdlX2FmdGVyGAUgASgFUgpzdGFnZUFmdGVyEh8KC3Jldmlld2VkX2F0GAYgASgJUg'
    'pyZXZpZXdlZEF0Eh4KC2lzX25ld19jYXJkGAcgASgIUglpc05ld0NhcmQSLwoRY2xpZW50X3Jl'
    'cXVlc3RfaWQYCCABKAlIAFIPY2xpZW50UmVxdWVzdElkiAEBEiwKD2xlYXJuaW5nX29yaWdpbh'
    'gJIAEoCUgBUg5sZWFybmluZ09yaWdpbogBAUIUChJfY2xpZW50X3JlcXVlc3RfaWRCEgoQX2xl'
    'YXJuaW5nX29yaWdpbg==');

@$core.Deprecated('Use syncResponseDescriptor instead')
const SyncResponse$json = {
  '1': 'SyncResponse',
  '2': [
    {'1': 'server_time', '3': 1, '4': 1, '5': 9, '10': 'serverTime'},
    {
      '1': 'user',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.karisreview.User',
      '10': 'user'
    },
    {
      '1': 'decks',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.karisreview.Deck',
      '10': 'decks'
    },
    {
      '1': 'review_logs',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.karisreview.ReviewLog',
      '10': 'reviewLogs'
    },
    {'1': 'deleted_deck_ids', '3': 5, '4': 3, '5': 9, '10': 'deletedDeckIds'},
    {'1': 'deleted_card_ids', '3': 6, '4': 3, '5': 9, '10': 'deletedCardIds'},
    {
      '1': 'deleted_review_log_ids',
      '3': 7,
      '4': 3,
      '5': 9,
      '10': 'deletedReviewLogIds'
    },
    {'1': 'event_cursor', '3': 8, '4': 1, '5': 3, '10': 'eventCursor'},
    {'1': 'has_more', '3': 9, '4': 1, '5': 8, '10': 'hasMore'},
    {'1': 'reset_required', '3': 10, '4': 1, '5': 8, '10': 'resetRequired'},
    {
      '1': 'changed_cards',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.karisreview.Card',
      '10': 'changedCards'
    },
  ],
};

/// Descriptor for `SyncResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncResponseDescriptor = $convert.base64Decode(
    'CgxTeW5jUmVzcG9uc2USHwoLc2VydmVyX3RpbWUYASABKAlSCnNlcnZlclRpbWUSJQoEdXNlch'
    'gCIAEoCzIRLmthcmlzcmV2aWV3LlVzZXJSBHVzZXISJwoFZGVja3MYAyADKAsyES5rYXJpc3Jl'
    'dmlldy5EZWNrUgVkZWNrcxI3CgtyZXZpZXdfbG9ncxgEIAMoCzIWLmthcmlzcmV2aWV3LlJldm'
    'lld0xvZ1IKcmV2aWV3TG9ncxIoChBkZWxldGVkX2RlY2tfaWRzGAUgAygJUg5kZWxldGVkRGVj'
    'a0lkcxIoChBkZWxldGVkX2NhcmRfaWRzGAYgAygJUg5kZWxldGVkQ2FyZElkcxIzChZkZWxldG'
    'VkX3Jldmlld19sb2dfaWRzGAcgAygJUhNkZWxldGVkUmV2aWV3TG9nSWRzEiEKDGV2ZW50X2N1'
    'cnNvchgIIAEoA1ILZXZlbnRDdXJzb3ISGQoIaGFzX21vcmUYCSABKAhSB2hhc01vcmUSJQoOcm'
    'VzZXRfcmVxdWlyZWQYCiABKAhSDXJlc2V0UmVxdWlyZWQSNgoNY2hhbmdlZF9jYXJkcxgLIAMo'
    'CzIRLmthcmlzcmV2aWV3LkNhcmRSDGNoYW5nZWRDYXJkcw==');

@$core.Deprecated('Use reviewCardDescriptor instead')
const ReviewCard$json = {
  '1': 'ReviewCard',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'deck_id', '3': 2, '4': 1, '5': 9, '10': 'deckId'},
    {'1': 'front', '3': 3, '4': 1, '5': 9, '10': 'front'},
    {'1': 'back', '3': 4, '4': 1, '5': 9, '10': 'back'},
    {'1': 'stage', '3': 5, '4': 1, '5': 5, '10': 'stage'},
    {'1': 'learning_mode', '3': 6, '4': 1, '5': 8, '10': 'learningMode'},
    {
      '1': 'consecutive_familiar',
      '3': 7,
      '4': 1,
      '5': 5,
      '10': 'consecutiveFamiliar'
    },
    {'1': 'learning_step', '3': 8, '4': 1, '5': 5, '10': 'learningStep'},
    {
      '1': 'reentry_stage',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'reentryStage',
      '17': true
    },
    {
      '1': 'next_review_date',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'nextReviewDate',
      '17': true
    },
    {'1': 'review_version', '3': 11, '4': 1, '5': 3, '10': 'reviewVersion'},
    {
      '1': 'learning_origin',
      '3': 12,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'learningOrigin',
      '17': true
    },
  ],
  '8': [
    {'1': '_reentry_stage'},
    {'1': '_next_review_date'},
    {'1': '_learning_origin'},
  ],
};

/// Descriptor for `ReviewCard`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewCardDescriptor = $convert.base64Decode(
    'CgpSZXZpZXdDYXJkEg4KAmlkGAEgASgJUgJpZBIXCgdkZWNrX2lkGAIgASgJUgZkZWNrSWQSFA'
    'oFZnJvbnQYAyABKAlSBWZyb250EhIKBGJhY2sYBCABKAlSBGJhY2sSFAoFc3RhZ2UYBSABKAVS'
    'BXN0YWdlEiMKDWxlYXJuaW5nX21vZGUYBiABKAhSDGxlYXJuaW5nTW9kZRIxChRjb25zZWN1dG'
    'l2ZV9mYW1pbGlhchgHIAEoBVITY29uc2VjdXRpdmVGYW1pbGlhchIjCg1sZWFybmluZ19zdGVw'
    'GAggASgFUgxsZWFybmluZ1N0ZXASKAoNcmVlbnRyeV9zdGFnZRgJIAEoCUgAUgxyZWVudHJ5U3'
    'RhZ2WIAQESLQoQbmV4dF9yZXZpZXdfZGF0ZRgKIAEoCUgBUg5uZXh0UmV2aWV3RGF0ZYgBARIl'
    'Cg5yZXZpZXdfdmVyc2lvbhgLIAEoA1INcmV2aWV3VmVyc2lvbhIsCg9sZWFybmluZ19vcmlnaW'
    '4YDCABKAlIAlIObGVhcm5pbmdPcmlnaW6IAQFCEAoOX3JlZW50cnlfc3RhZ2VCEwoRX25leHRf'
    'cmV2aWV3X2RhdGVCEgoQX2xlYXJuaW5nX29yaWdpbg==');

@$core.Deprecated('Use reviewCardListResponseDescriptor instead')
const ReviewCardListResponse$json = {
  '1': 'ReviewCardListResponse',
  '2': [
    {
      '1': 'cards',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.karisreview.ReviewCard',
      '10': 'cards'
    },
  ],
};

/// Descriptor for `ReviewCardListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewCardListResponseDescriptor =
    $convert.base64Decode(
        'ChZSZXZpZXdDYXJkTGlzdFJlc3BvbnNlEi0KBWNhcmRzGAEgAygLMhcua2FyaXNyZXZpZXcuUm'
        'V2aWV3Q2FyZFIFY2FyZHM=');

@$core.Deprecated('Use reviewSessionCreateRequestDescriptor instead')
const ReviewSessionCreateRequest$json = {
  '1': 'ReviewSessionCreateRequest',
  '2': [
    {'1': 'mode', '3': 1, '4': 1, '5': 9, '10': 'mode'},
    {
      '1': 'deck_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'deckId',
      '17': true
    },
    {'1': 'batch_size', '3': 3, '4': 1, '5': 5, '10': 'batchSize'},
  ],
  '8': [
    {'1': '_deck_id'},
  ],
};

/// Descriptor for `ReviewSessionCreateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewSessionCreateRequestDescriptor =
    $convert.base64Decode(
        'ChpSZXZpZXdTZXNzaW9uQ3JlYXRlUmVxdWVzdBISCgRtb2RlGAEgASgJUgRtb2RlEhwKB2RlY2'
        'tfaWQYAiABKAlIAFIGZGVja0lkiAEBEh0KCmJhdGNoX3NpemUYAyABKAVSCWJhdGNoU2l6ZUIK'
        'CghfZGVja19pZA==');

@$core.Deprecated('Use reviewSessionPageResponseDescriptor instead')
const ReviewSessionPageResponse$json = {
  '1': 'ReviewSessionPageResponse',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'mode', '3': 2, '4': 1, '5': 9, '10': 'mode'},
    {
      '1': 'deck_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'deckId',
      '17': true
    },
    {'1': 'batch_size', '3': 4, '4': 1, '5': 5, '10': 'batchSize'},
    {'1': 'total', '3': 5, '4': 1, '5': 5, '10': 'total'},
    {'1': 'cursor', '3': 6, '4': 1, '5': 5, '10': 'cursor'},
    {'1': 'has_more', '3': 7, '4': 1, '5': 8, '10': 'hasMore'},
    {
      '1': 'cards',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.karisreview.ReviewCard',
      '10': 'cards'
    },
  ],
  '8': [
    {'1': '_deck_id'},
  ],
};

/// Descriptor for `ReviewSessionPageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewSessionPageResponseDescriptor = $convert.base64Decode(
    'ChlSZXZpZXdTZXNzaW9uUGFnZVJlc3BvbnNlEh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb2'
    '5JZBISCgRtb2RlGAIgASgJUgRtb2RlEhwKB2RlY2tfaWQYAyABKAlIAFIGZGVja0lkiAEBEh0K'
    'CmJhdGNoX3NpemUYBCABKAVSCWJhdGNoU2l6ZRIUCgV0b3RhbBgFIAEoBVIFdG90YWwSFgoGY3'
    'Vyc29yGAYgASgFUgZjdXJzb3ISGQoIaGFzX21vcmUYByABKAhSB2hhc01vcmUSLQoFY2FyZHMY'
    'CCADKAsyFy5rYXJpc3Jldmlldy5SZXZpZXdDYXJkUgVjYXJkc0IKCghfZGVja19pZA==');

@$core.Deprecated('Use reviewSyncRequestDescriptor instead')
const ReviewSyncRequest$json = {
  '1': 'ReviewSyncRequest',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.karisreview.ReviewSyncItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ReviewSyncRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewSyncRequestDescriptor = $convert.base64Decode(
    'ChFSZXZpZXdTeW5jUmVxdWVzdBIxCgVpdGVtcxgBIAMoCzIbLmthcmlzcmV2aWV3LlJldmlld1'
    'N5bmNJdGVtUgVpdGVtcw==');

@$core.Deprecated('Use reviewSyncItemDescriptor instead')
const ReviewSyncItem$json = {
  '1': 'ReviewSyncItem',
  '2': [
    {'1': 'client_request_id', '3': 1, '4': 1, '5': 9, '10': 'clientRequestId'},
    {'1': 'card_id', '3': 2, '4': 1, '5': 9, '10': 'cardId'},
    {'1': 'rating', '3': 3, '4': 1, '5': 9, '10': 'rating'},
    {'1': 'rated_at', '3': 4, '4': 1, '5': 9, '10': 'ratedAt'},
    {'1': 'review_version', '3': 5, '4': 1, '5': 3, '10': 'reviewVersion'},
  ],
};

/// Descriptor for `ReviewSyncItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewSyncItemDescriptor = $convert.base64Decode(
    'Cg5SZXZpZXdTeW5jSXRlbRIqChFjbGllbnRfcmVxdWVzdF9pZBgBIAEoCVIPY2xpZW50UmVxdW'
    'VzdElkEhcKB2NhcmRfaWQYAiABKAlSBmNhcmRJZBIWCgZyYXRpbmcYAyABKAlSBnJhdGluZxIZ'
    'CghyYXRlZF9hdBgEIAEoCVIHcmF0ZWRBdBIlCg5yZXZpZXdfdmVyc2lvbhgFIAEoA1INcmV2aW'
    'V3VmVyc2lvbg==');

@$core.Deprecated('Use reviewSyncResponseDescriptor instead')
const ReviewSyncResponse$json = {
  '1': 'ReviewSyncResponse',
  '2': [
    {'1': 'synced', '3': 1, '4': 1, '5': 5, '10': 'synced'},
    {'1': 'conflicts', '3': 2, '4': 1, '5': 5, '10': 'conflicts'},
    {'1': 'missing', '3': 3, '4': 1, '5': 5, '10': 'missing'},
    {
      '1': 'items',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.karisreview.ReviewSyncItemResult',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ReviewSyncResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewSyncResponseDescriptor = $convert.base64Decode(
    'ChJSZXZpZXdTeW5jUmVzcG9uc2USFgoGc3luY2VkGAEgASgFUgZzeW5jZWQSHAoJY29uZmxpY3'
    'RzGAIgASgFUgljb25mbGljdHMSGAoHbWlzc2luZxgDIAEoBVIHbWlzc2luZxI3CgVpdGVtcxgE'
    'IAMoCzIhLmthcmlzcmV2aWV3LlJldmlld1N5bmNJdGVtUmVzdWx0UgVpdGVtcw==');

@$core.Deprecated('Use reviewSyncItemResultDescriptor instead')
const ReviewSyncItemResult$json = {
  '1': 'ReviewSyncItemResult',
  '2': [
    {'1': 'client_request_id', '3': 1, '4': 1, '5': 9, '10': 'clientRequestId'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'current_card',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.karisreview.ReviewCard',
      '9': 0,
      '10': 'currentCard',
      '17': true
    },
    {
      '1': 'card_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'cardId',
      '17': true
    },
  ],
  '8': [
    {'1': '_current_card'},
    {'1': '_card_id'},
  ],
};

/// Descriptor for `ReviewSyncItemResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewSyncItemResultDescriptor = $convert.base64Decode(
    'ChRSZXZpZXdTeW5jSXRlbVJlc3VsdBIqChFjbGllbnRfcmVxdWVzdF9pZBgBIAEoCVIPY2xpZW'
    '50UmVxdWVzdElkEhYKBnN0YXR1cxgCIAEoCVIGc3RhdHVzEj8KDGN1cnJlbnRfY2FyZBgDIAEo'
    'CzIXLmthcmlzcmV2aWV3LlJldmlld0NhcmRIAFILY3VycmVudENhcmSIAQESHAoHY2FyZF9pZB'
    'gEIAEoCUgBUgZjYXJkSWSIAQFCDwoNX2N1cnJlbnRfY2FyZEIKCghfY2FyZF9pZA==');

@$core.Deprecated('Use apiErrorDescriptor instead')
const ApiError$json = {
  '1': 'ApiError',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 5, '10': 'code'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ApiError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List apiErrorDescriptor = $convert.base64Decode(
    'CghBcGlFcnJvchISCgRjb2RlGAEgASgFUgRjb2RlEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2'
    'U=');
