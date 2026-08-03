// This is a generated file - do not edit.
//
// Generated from karis_review.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class User extends $pb.GeneratedMessage {
  factory User({
    $core.String? id,
    $core.String? email,
    $core.String? refreshTime,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (email != null) result.email = email;
    if (refreshTime != null) result.refreshTime = refreshTime;
    return result;
  }

  User._();

  factory User.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory User.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'User',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'email')
    ..aOS(3, _omitFieldNames ? '' : 'refreshTime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User copyWith(void Function(User) updates) =>
      super.copyWith((message) => updates(message as User)) as User;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static User create() => User._();
  @$core.override
  User createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static User getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<User>(create);
  static User? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get email => $_getSZ(1);
  @$pb.TagNumber(2)
  set email($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEmail() => $_has(1);
  @$pb.TagNumber(2)
  void clearEmail() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get refreshTime => $_getSZ(2);
  @$pb.TagNumber(3)
  set refreshTime($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRefreshTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearRefreshTime() => $_clearField(3);
}

class Card extends $pb.GeneratedMessage {
  factory Card({
    $core.String? id,
    $core.String? deckId,
    $core.String? front,
    $core.String? back,
    $core.int? stage,
    $core.int? consecutiveFamiliar,
    $core.String? nextReviewDate,
    $core.bool? learningMode,
    $core.String? reentryStage,
    $core.int? learningStep,
    $fixnum.Int64? reviewVersion,
    $core.String? createdAt,
    $core.String? updatedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (deckId != null) result.deckId = deckId;
    if (front != null) result.front = front;
    if (back != null) result.back = back;
    if (stage != null) result.stage = stage;
    if (consecutiveFamiliar != null)
      result.consecutiveFamiliar = consecutiveFamiliar;
    if (nextReviewDate != null) result.nextReviewDate = nextReviewDate;
    if (learningMode != null) result.learningMode = learningMode;
    if (reentryStage != null) result.reentryStage = reentryStage;
    if (learningStep != null) result.learningStep = learningStep;
    if (reviewVersion != null) result.reviewVersion = reviewVersion;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  Card._();

  factory Card.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Card.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Card',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'deckId')
    ..aOS(3, _omitFieldNames ? '' : 'front')
    ..aOS(4, _omitFieldNames ? '' : 'back')
    ..aI(5, _omitFieldNames ? '' : 'stage')
    ..aI(6, _omitFieldNames ? '' : 'consecutiveFamiliar')
    ..aOS(7, _omitFieldNames ? '' : 'nextReviewDate')
    ..aOB(8, _omitFieldNames ? '' : 'learningMode')
    ..aOS(9, _omitFieldNames ? '' : 'reentryStage')
    ..aI(10, _omitFieldNames ? '' : 'learningStep')
    ..aInt64(11, _omitFieldNames ? '' : 'reviewVersion')
    ..aOS(12, _omitFieldNames ? '' : 'createdAt')
    ..aOS(13, _omitFieldNames ? '' : 'updatedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Card clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Card copyWith(void Function(Card) updates) =>
      super.copyWith((message) => updates(message as Card)) as Card;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Card create() => Card._();
  @$core.override
  Card createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Card getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Card>(create);
  static Card? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deckId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deckId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeckId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeckId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get front => $_getSZ(2);
  @$pb.TagNumber(3)
  set front($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFront() => $_has(2);
  @$pb.TagNumber(3)
  void clearFront() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get back => $_getSZ(3);
  @$pb.TagNumber(4)
  set back($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBack() => $_has(3);
  @$pb.TagNumber(4)
  void clearBack() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get stage => $_getIZ(4);
  @$pb.TagNumber(5)
  set stage($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStage() => $_has(4);
  @$pb.TagNumber(5)
  void clearStage() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get consecutiveFamiliar => $_getIZ(5);
  @$pb.TagNumber(6)
  set consecutiveFamiliar($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasConsecutiveFamiliar() => $_has(5);
  @$pb.TagNumber(6)
  void clearConsecutiveFamiliar() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get nextReviewDate => $_getSZ(6);
  @$pb.TagNumber(7)
  set nextReviewDate($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNextReviewDate() => $_has(6);
  @$pb.TagNumber(7)
  void clearNextReviewDate() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get learningMode => $_getBF(7);
  @$pb.TagNumber(8)
  set learningMode($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLearningMode() => $_has(7);
  @$pb.TagNumber(8)
  void clearLearningMode() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get reentryStage => $_getSZ(8);
  @$pb.TagNumber(9)
  set reentryStage($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasReentryStage() => $_has(8);
  @$pb.TagNumber(9)
  void clearReentryStage() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get learningStep => $_getIZ(9);
  @$pb.TagNumber(10)
  set learningStep($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLearningStep() => $_has(9);
  @$pb.TagNumber(10)
  void clearLearningStep() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get reviewVersion => $_getI64(10);
  @$pb.TagNumber(11)
  set reviewVersion($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasReviewVersion() => $_has(10);
  @$pb.TagNumber(11)
  void clearReviewVersion() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get createdAt => $_getSZ(11);
  @$pb.TagNumber(12)
  set createdAt($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCreatedAt() => $_has(11);
  @$pb.TagNumber(12)
  void clearCreatedAt() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get updatedAt => $_getSZ(12);
  @$pb.TagNumber(13)
  set updatedAt($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasUpdatedAt() => $_has(12);
  @$pb.TagNumber(13)
  void clearUpdatedAt() => $_clearField(13);
}

class Deck extends $pb.GeneratedMessage {
  factory Deck({
    $core.String? id,
    $core.String? name,
    $core.String? createdAt,
    $core.String? updatedAt,
    $core.Iterable<Card>? cards,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (cards != null) result.cards.addAll(cards);
    return result;
  }

  Deck._();

  factory Deck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Deck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Deck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'createdAt')
    ..aOS(4, _omitFieldNames ? '' : 'updatedAt')
    ..pPM<Card>(5, _omitFieldNames ? '' : 'cards', subBuilder: Card.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Deck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Deck copyWith(void Function(Deck) updates) =>
      super.copyWith((message) => updates(message as Deck)) as Deck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Deck create() => Deck._();
  @$core.override
  Deck createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Deck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Deck>(create);
  static Deck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get createdAt => $_getSZ(2);
  @$pb.TagNumber(3)
  set createdAt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedAt() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get updatedAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set updatedAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUpdatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdatedAt() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<Card> get cards => $_getList(4);
}

class ReviewLog extends $pb.GeneratedMessage {
  factory ReviewLog({
    $core.String? id,
    $core.String? cardId,
    $core.String? rating,
    $core.int? stageBefore,
    $core.int? stageAfter,
    $core.String? reviewedAt,
    $core.bool? isNewCard,
    $core.String? clientRequestId,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (cardId != null) result.cardId = cardId;
    if (rating != null) result.rating = rating;
    if (stageBefore != null) result.stageBefore = stageBefore;
    if (stageAfter != null) result.stageAfter = stageAfter;
    if (reviewedAt != null) result.reviewedAt = reviewedAt;
    if (isNewCard != null) result.isNewCard = isNewCard;
    if (clientRequestId != null) result.clientRequestId = clientRequestId;
    return result;
  }

  ReviewLog._();

  factory ReviewLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReviewLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReviewLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'cardId')
    ..aOS(3, _omitFieldNames ? '' : 'rating')
    ..aI(4, _omitFieldNames ? '' : 'stageBefore')
    ..aI(5, _omitFieldNames ? '' : 'stageAfter')
    ..aOS(6, _omitFieldNames ? '' : 'reviewedAt')
    ..aOB(7, _omitFieldNames ? '' : 'isNewCard')
    ..aOS(8, _omitFieldNames ? '' : 'clientRequestId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewLog copyWith(void Function(ReviewLog) updates) =>
      super.copyWith((message) => updates(message as ReviewLog)) as ReviewLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReviewLog create() => ReviewLog._();
  @$core.override
  ReviewLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReviewLog getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReviewLog>(create);
  static ReviewLog? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get cardId => $_getSZ(1);
  @$pb.TagNumber(2)
  set cardId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCardId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCardId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get rating => $_getSZ(2);
  @$pb.TagNumber(3)
  set rating($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRating() => $_has(2);
  @$pb.TagNumber(3)
  void clearRating() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get stageBefore => $_getIZ(3);
  @$pb.TagNumber(4)
  set stageBefore($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStageBefore() => $_has(3);
  @$pb.TagNumber(4)
  void clearStageBefore() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get stageAfter => $_getIZ(4);
  @$pb.TagNumber(5)
  set stageAfter($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStageAfter() => $_has(4);
  @$pb.TagNumber(5)
  void clearStageAfter() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get reviewedAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set reviewedAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReviewedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearReviewedAt() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get isNewCard => $_getBF(6);
  @$pb.TagNumber(7)
  set isNewCard($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIsNewCard() => $_has(6);
  @$pb.TagNumber(7)
  void clearIsNewCard() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get clientRequestId => $_getSZ(7);
  @$pb.TagNumber(8)
  set clientRequestId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasClientRequestId() => $_has(7);
  @$pb.TagNumber(8)
  void clearClientRequestId() => $_clearField(8);
}

class SyncResponse extends $pb.GeneratedMessage {
  factory SyncResponse({
    $core.String? serverTime,
    User? user,
    $core.Iterable<Deck>? decks,
    $core.Iterable<ReviewLog>? reviewLogs,
    $core.Iterable<$core.String>? deletedDeckIds,
    $core.Iterable<$core.String>? deletedCardIds,
    $core.Iterable<$core.String>? deletedReviewLogIds,
    $fixnum.Int64? eventCursor,
    $core.bool? hasMore,
    $core.bool? resetRequired,
    $core.Iterable<Card>? changedCards,
  }) {
    final result = create();
    if (serverTime != null) result.serverTime = serverTime;
    if (user != null) result.user = user;
    if (decks != null) result.decks.addAll(decks);
    if (reviewLogs != null) result.reviewLogs.addAll(reviewLogs);
    if (deletedDeckIds != null) result.deletedDeckIds.addAll(deletedDeckIds);
    if (deletedCardIds != null) result.deletedCardIds.addAll(deletedCardIds);
    if (deletedReviewLogIds != null)
      result.deletedReviewLogIds.addAll(deletedReviewLogIds);
    if (eventCursor != null) result.eventCursor = eventCursor;
    if (hasMore != null) result.hasMore = hasMore;
    if (resetRequired != null) result.resetRequired = resetRequired;
    if (changedCards != null) result.changedCards.addAll(changedCards);
    return result;
  }

  SyncResponse._();

  factory SyncResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SyncResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverTime')
    ..aOM<User>(2, _omitFieldNames ? '' : 'user', subBuilder: User.create)
    ..pPM<Deck>(3, _omitFieldNames ? '' : 'decks', subBuilder: Deck.create)
    ..pPM<ReviewLog>(4, _omitFieldNames ? '' : 'reviewLogs',
        subBuilder: ReviewLog.create)
    ..pPS(5, _omitFieldNames ? '' : 'deletedDeckIds')
    ..pPS(6, _omitFieldNames ? '' : 'deletedCardIds')
    ..pPS(7, _omitFieldNames ? '' : 'deletedReviewLogIds')
    ..aInt64(8, _omitFieldNames ? '' : 'eventCursor')
    ..aOB(9, _omitFieldNames ? '' : 'hasMore')
    ..aOB(10, _omitFieldNames ? '' : 'resetRequired')
    ..pPM<Card>(11, _omitFieldNames ? '' : 'changedCards',
        subBuilder: Card.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncResponse copyWith(void Function(SyncResponse) updates) =>
      super.copyWith((message) => updates(message as SyncResponse))
          as SyncResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncResponse create() => SyncResponse._();
  @$core.override
  SyncResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SyncResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncResponse>(create);
  static SyncResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverTime => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverTime($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerTime() => $_clearField(1);

  @$pb.TagNumber(2)
  User get user => $_getN(1);
  @$pb.TagNumber(2)
  set user(User value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUser() => $_has(1);
  @$pb.TagNumber(2)
  void clearUser() => $_clearField(2);
  @$pb.TagNumber(2)
  User ensureUser() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<Deck> get decks => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<ReviewLog> get reviewLogs => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get deletedDeckIds => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get deletedCardIds => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get deletedReviewLogIds => $_getList(6);

  @$pb.TagNumber(8)
  $fixnum.Int64 get eventCursor => $_getI64(7);
  @$pb.TagNumber(8)
  set eventCursor($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEventCursor() => $_has(7);
  @$pb.TagNumber(8)
  void clearEventCursor() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get hasMore => $_getBF(8);
  @$pb.TagNumber(9)
  set hasMore($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHasMore() => $_has(8);
  @$pb.TagNumber(9)
  void clearHasMore() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get resetRequired => $_getBF(9);
  @$pb.TagNumber(10)
  set resetRequired($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasResetRequired() => $_has(9);
  @$pb.TagNumber(10)
  void clearResetRequired() => $_clearField(10);

  @$pb.TagNumber(11)
  $pb.PbList<Card> get changedCards => $_getList(10);
}

class ReviewCard extends $pb.GeneratedMessage {
  factory ReviewCard({
    $core.String? id,
    $core.String? deckId,
    $core.String? front,
    $core.String? back,
    $core.int? stage,
    $core.bool? learningMode,
    $core.int? consecutiveFamiliar,
    $core.int? learningStep,
    $core.String? reentryStage,
    $core.String? nextReviewDate,
    $fixnum.Int64? reviewVersion,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (deckId != null) result.deckId = deckId;
    if (front != null) result.front = front;
    if (back != null) result.back = back;
    if (stage != null) result.stage = stage;
    if (learningMode != null) result.learningMode = learningMode;
    if (consecutiveFamiliar != null)
      result.consecutiveFamiliar = consecutiveFamiliar;
    if (learningStep != null) result.learningStep = learningStep;
    if (reentryStage != null) result.reentryStage = reentryStage;
    if (nextReviewDate != null) result.nextReviewDate = nextReviewDate;
    if (reviewVersion != null) result.reviewVersion = reviewVersion;
    return result;
  }

  ReviewCard._();

  factory ReviewCard.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReviewCard.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReviewCard',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'deckId')
    ..aOS(3, _omitFieldNames ? '' : 'front')
    ..aOS(4, _omitFieldNames ? '' : 'back')
    ..aI(5, _omitFieldNames ? '' : 'stage')
    ..aOB(6, _omitFieldNames ? '' : 'learningMode')
    ..aI(7, _omitFieldNames ? '' : 'consecutiveFamiliar')
    ..aI(8, _omitFieldNames ? '' : 'learningStep')
    ..aOS(9, _omitFieldNames ? '' : 'reentryStage')
    ..aOS(10, _omitFieldNames ? '' : 'nextReviewDate')
    ..aInt64(11, _omitFieldNames ? '' : 'reviewVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewCard clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewCard copyWith(void Function(ReviewCard) updates) =>
      super.copyWith((message) => updates(message as ReviewCard)) as ReviewCard;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReviewCard create() => ReviewCard._();
  @$core.override
  ReviewCard createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReviewCard getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReviewCard>(create);
  static ReviewCard? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deckId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deckId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeckId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeckId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get front => $_getSZ(2);
  @$pb.TagNumber(3)
  set front($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFront() => $_has(2);
  @$pb.TagNumber(3)
  void clearFront() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get back => $_getSZ(3);
  @$pb.TagNumber(4)
  set back($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBack() => $_has(3);
  @$pb.TagNumber(4)
  void clearBack() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get stage => $_getIZ(4);
  @$pb.TagNumber(5)
  set stage($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStage() => $_has(4);
  @$pb.TagNumber(5)
  void clearStage() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get learningMode => $_getBF(5);
  @$pb.TagNumber(6)
  set learningMode($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLearningMode() => $_has(5);
  @$pb.TagNumber(6)
  void clearLearningMode() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get consecutiveFamiliar => $_getIZ(6);
  @$pb.TagNumber(7)
  set consecutiveFamiliar($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasConsecutiveFamiliar() => $_has(6);
  @$pb.TagNumber(7)
  void clearConsecutiveFamiliar() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get learningStep => $_getIZ(7);
  @$pb.TagNumber(8)
  set learningStep($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLearningStep() => $_has(7);
  @$pb.TagNumber(8)
  void clearLearningStep() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get reentryStage => $_getSZ(8);
  @$pb.TagNumber(9)
  set reentryStage($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasReentryStage() => $_has(8);
  @$pb.TagNumber(9)
  void clearReentryStage() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get nextReviewDate => $_getSZ(9);
  @$pb.TagNumber(10)
  set nextReviewDate($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasNextReviewDate() => $_has(9);
  @$pb.TagNumber(10)
  void clearNextReviewDate() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get reviewVersion => $_getI64(10);
  @$pb.TagNumber(11)
  set reviewVersion($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasReviewVersion() => $_has(10);
  @$pb.TagNumber(11)
  void clearReviewVersion() => $_clearField(11);
}

class ReviewCardListResponse extends $pb.GeneratedMessage {
  factory ReviewCardListResponse({
    $core.Iterable<ReviewCard>? cards,
  }) {
    final result = create();
    if (cards != null) result.cards.addAll(cards);
    return result;
  }

  ReviewCardListResponse._();

  factory ReviewCardListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReviewCardListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReviewCardListResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..pPM<ReviewCard>(1, _omitFieldNames ? '' : 'cards',
        subBuilder: ReviewCard.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewCardListResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewCardListResponse copyWith(
          void Function(ReviewCardListResponse) updates) =>
      super.copyWith((message) => updates(message as ReviewCardListResponse))
          as ReviewCardListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReviewCardListResponse create() => ReviewCardListResponse._();
  @$core.override
  ReviewCardListResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReviewCardListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReviewCardListResponse>(create);
  static ReviewCardListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ReviewCard> get cards => $_getList(0);
}

class ReviewSessionCreateRequest extends $pb.GeneratedMessage {
  factory ReviewSessionCreateRequest({
    $core.String? mode,
    $core.String? deckId,
    $core.int? batchSize,
  }) {
    final result = create();
    if (mode != null) result.mode = mode;
    if (deckId != null) result.deckId = deckId;
    if (batchSize != null) result.batchSize = batchSize;
    return result;
  }

  ReviewSessionCreateRequest._();

  factory ReviewSessionCreateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReviewSessionCreateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReviewSessionCreateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'mode')
    ..aOS(2, _omitFieldNames ? '' : 'deckId')
    ..aI(3, _omitFieldNames ? '' : 'batchSize')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSessionCreateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSessionCreateRequest copyWith(
          void Function(ReviewSessionCreateRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ReviewSessionCreateRequest))
          as ReviewSessionCreateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReviewSessionCreateRequest create() => ReviewSessionCreateRequest._();
  @$core.override
  ReviewSessionCreateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReviewSessionCreateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReviewSessionCreateRequest>(create);
  static ReviewSessionCreateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mode => $_getSZ(0);
  @$pb.TagNumber(1)
  set mode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearMode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deckId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deckId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeckId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeckId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get batchSize => $_getIZ(2);
  @$pb.TagNumber(3)
  set batchSize($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBatchSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearBatchSize() => $_clearField(3);
}

class ReviewSessionPageResponse extends $pb.GeneratedMessage {
  factory ReviewSessionPageResponse({
    $core.String? sessionId,
    $core.String? mode,
    $core.String? deckId,
    $core.int? batchSize,
    $core.int? total,
    $core.int? cursor,
    $core.bool? hasMore,
    $core.Iterable<ReviewCard>? cards,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (mode != null) result.mode = mode;
    if (deckId != null) result.deckId = deckId;
    if (batchSize != null) result.batchSize = batchSize;
    if (total != null) result.total = total;
    if (cursor != null) result.cursor = cursor;
    if (hasMore != null) result.hasMore = hasMore;
    if (cards != null) result.cards.addAll(cards);
    return result;
  }

  ReviewSessionPageResponse._();

  factory ReviewSessionPageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReviewSessionPageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReviewSessionPageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'mode')
    ..aOS(3, _omitFieldNames ? '' : 'deckId')
    ..aI(4, _omitFieldNames ? '' : 'batchSize')
    ..aI(5, _omitFieldNames ? '' : 'total')
    ..aI(6, _omitFieldNames ? '' : 'cursor')
    ..aOB(7, _omitFieldNames ? '' : 'hasMore')
    ..pPM<ReviewCard>(8, _omitFieldNames ? '' : 'cards',
        subBuilder: ReviewCard.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSessionPageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSessionPageResponse copyWith(
          void Function(ReviewSessionPageResponse) updates) =>
      super.copyWith((message) => updates(message as ReviewSessionPageResponse))
          as ReviewSessionPageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReviewSessionPageResponse create() => ReviewSessionPageResponse._();
  @$core.override
  ReviewSessionPageResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReviewSessionPageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReviewSessionPageResponse>(create);
  static ReviewSessionPageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get mode => $_getSZ(1);
  @$pb.TagNumber(2)
  set mode($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get deckId => $_getSZ(2);
  @$pb.TagNumber(3)
  set deckId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeckId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeckId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get batchSize => $_getIZ(3);
  @$pb.TagNumber(4)
  set batchSize($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBatchSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearBatchSize() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get total => $_getIZ(4);
  @$pb.TagNumber(5)
  set total($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotal() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotal() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get cursor => $_getIZ(5);
  @$pb.TagNumber(6)
  set cursor($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCursor() => $_has(5);
  @$pb.TagNumber(6)
  void clearCursor() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get hasMore => $_getBF(6);
  @$pb.TagNumber(7)
  set hasMore($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHasMore() => $_has(6);
  @$pb.TagNumber(7)
  void clearHasMore() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<ReviewCard> get cards => $_getList(7);
}

class ReviewSyncRequest extends $pb.GeneratedMessage {
  factory ReviewSyncRequest({
    $core.Iterable<ReviewSyncItem>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ReviewSyncRequest._();

  factory ReviewSyncRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReviewSyncRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReviewSyncRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..pPM<ReviewSyncItem>(1, _omitFieldNames ? '' : 'items',
        subBuilder: ReviewSyncItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSyncRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSyncRequest copyWith(void Function(ReviewSyncRequest) updates) =>
      super.copyWith((message) => updates(message as ReviewSyncRequest))
          as ReviewSyncRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReviewSyncRequest create() => ReviewSyncRequest._();
  @$core.override
  ReviewSyncRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReviewSyncRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReviewSyncRequest>(create);
  static ReviewSyncRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ReviewSyncItem> get items => $_getList(0);
}

class ReviewSyncItem extends $pb.GeneratedMessage {
  factory ReviewSyncItem({
    $core.String? clientRequestId,
    $core.String? cardId,
    $core.String? rating,
    $core.String? ratedAt,
    $fixnum.Int64? reviewVersion,
  }) {
    final result = create();
    if (clientRequestId != null) result.clientRequestId = clientRequestId;
    if (cardId != null) result.cardId = cardId;
    if (rating != null) result.rating = rating;
    if (ratedAt != null) result.ratedAt = ratedAt;
    if (reviewVersion != null) result.reviewVersion = reviewVersion;
    return result;
  }

  ReviewSyncItem._();

  factory ReviewSyncItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReviewSyncItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReviewSyncItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'clientRequestId')
    ..aOS(2, _omitFieldNames ? '' : 'cardId')
    ..aOS(3, _omitFieldNames ? '' : 'rating')
    ..aOS(4, _omitFieldNames ? '' : 'ratedAt')
    ..aInt64(5, _omitFieldNames ? '' : 'reviewVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSyncItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSyncItem copyWith(void Function(ReviewSyncItem) updates) =>
      super.copyWith((message) => updates(message as ReviewSyncItem))
          as ReviewSyncItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReviewSyncItem create() => ReviewSyncItem._();
  @$core.override
  ReviewSyncItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReviewSyncItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReviewSyncItem>(create);
  static ReviewSyncItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientRequestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientRequestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get cardId => $_getSZ(1);
  @$pb.TagNumber(2)
  set cardId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCardId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCardId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get rating => $_getSZ(2);
  @$pb.TagNumber(3)
  set rating($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRating() => $_has(2);
  @$pb.TagNumber(3)
  void clearRating() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get ratedAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set ratedAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearRatedAt() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get reviewVersion => $_getI64(4);
  @$pb.TagNumber(5)
  set reviewVersion($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReviewVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearReviewVersion() => $_clearField(5);
}

class ReviewSyncResponse extends $pb.GeneratedMessage {
  factory ReviewSyncResponse({
    $core.int? synced,
    $core.int? conflicts,
    $core.int? missing,
    $core.Iterable<ReviewSyncItemResult>? items,
  }) {
    final result = create();
    if (synced != null) result.synced = synced;
    if (conflicts != null) result.conflicts = conflicts;
    if (missing != null) result.missing = missing;
    if (items != null) result.items.addAll(items);
    return result;
  }

  ReviewSyncResponse._();

  factory ReviewSyncResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReviewSyncResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReviewSyncResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'synced')
    ..aI(2, _omitFieldNames ? '' : 'conflicts')
    ..aI(3, _omitFieldNames ? '' : 'missing')
    ..pPM<ReviewSyncItemResult>(4, _omitFieldNames ? '' : 'items',
        subBuilder: ReviewSyncItemResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSyncResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSyncResponse copyWith(void Function(ReviewSyncResponse) updates) =>
      super.copyWith((message) => updates(message as ReviewSyncResponse))
          as ReviewSyncResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReviewSyncResponse create() => ReviewSyncResponse._();
  @$core.override
  ReviewSyncResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReviewSyncResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReviewSyncResponse>(create);
  static ReviewSyncResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get synced => $_getIZ(0);
  @$pb.TagNumber(1)
  set synced($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSynced() => $_has(0);
  @$pb.TagNumber(1)
  void clearSynced() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get conflicts => $_getIZ(1);
  @$pb.TagNumber(2)
  set conflicts($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConflicts() => $_has(1);
  @$pb.TagNumber(2)
  void clearConflicts() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get missing => $_getIZ(2);
  @$pb.TagNumber(3)
  set missing($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMissing() => $_has(2);
  @$pb.TagNumber(3)
  void clearMissing() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<ReviewSyncItemResult> get items => $_getList(3);
}

class ReviewSyncItemResult extends $pb.GeneratedMessage {
  factory ReviewSyncItemResult({
    $core.String? clientRequestId,
    $core.String? status,
    ReviewCard? currentCard,
    $core.String? cardId,
  }) {
    final result = create();
    if (clientRequestId != null) result.clientRequestId = clientRequestId;
    if (status != null) result.status = status;
    if (currentCard != null) result.currentCard = currentCard;
    if (cardId != null) result.cardId = cardId;
    return result;
  }

  ReviewSyncItemResult._();

  factory ReviewSyncItemResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReviewSyncItemResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReviewSyncItemResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'clientRequestId')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOM<ReviewCard>(3, _omitFieldNames ? '' : 'currentCard',
        subBuilder: ReviewCard.create)
    ..aOS(4, _omitFieldNames ? '' : 'cardId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSyncItemResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReviewSyncItemResult copyWith(void Function(ReviewSyncItemResult) updates) =>
      super.copyWith((message) => updates(message as ReviewSyncItemResult))
          as ReviewSyncItemResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReviewSyncItemResult create() => ReviewSyncItemResult._();
  @$core.override
  ReviewSyncItemResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReviewSyncItemResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReviewSyncItemResult>(create);
  static ReviewSyncItemResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientRequestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientRequestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  ReviewCard get currentCard => $_getN(2);
  @$pb.TagNumber(3)
  set currentCard(ReviewCard value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrentCard() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrentCard() => $_clearField(3);
  @$pb.TagNumber(3)
  ReviewCard ensureCurrentCard() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get cardId => $_getSZ(3);
  @$pb.TagNumber(4)
  set cardId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCardId() => $_has(3);
  @$pb.TagNumber(4)
  void clearCardId() => $_clearField(4);
}

class ApiError extends $pb.GeneratedMessage {
  factory ApiError({
    $core.int? code,
    $core.String? message,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    return result;
  }

  ApiError._();

  factory ApiError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApiError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApiError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'karisreview'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApiError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApiError copyWith(void Function(ApiError) updates) =>
      super.copyWith((message) => updates(message as ApiError)) as ApiError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApiError create() => ApiError._();
  @$core.override
  ApiError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApiError getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApiError>(create);
  static ApiError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get code => $_getIZ(0);
  @$pb.TagNumber(1)
  set code($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
