// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class KarisReviewLocalizationsZh extends KarisReviewLocalizations {
  KarisReviewLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Karis Review';

  @override
  String get navHome => '首页';

  @override
  String get navDecks => '卡组';

  @override
  String get navStats => '统计';

  @override
  String get navSettings => '设置';

  @override
  String get authLoginTitle => '登录';

  @override
  String get authLoginSubtitle => '登录后开始今天的复习';

  @override
  String get authRegisterSubtitle => '一个专注的间隔重复复习空间';

  @override
  String get authEmailLabel => '邮箱';

  @override
  String get authPasswordLabel => '密码';

  @override
  String get authInviteCodeLabel => '邀请码';

  @override
  String get authLoginButton => '登录';

  @override
  String get authRegisterButton => '注册';

  @override
  String get authNoAccount => '还没有账号？';

  @override
  String get authHasAccount => '已有账号？';

  @override
  String get authRegisterLink => '注册';

  @override
  String get authLoginLink => '登录';

  @override
  String get homeTitle => '首页';

  @override
  String get homeTodayReview => '今日待复习';

  @override
  String homeReviewedProgress(Object reviewed, Object due) {
    return '已复习 $reviewed · 还剩 $due';
  }

  @override
  String get homeNoCards => '今天没有待复习卡片';

  @override
  String get homeNoDecksTitle => '还没有卡组';

  @override
  String get homeNoDecksMessage => '创建第一个卡组，开始记录你的复习队列';

  @override
  String get homeCreateDeck => '创建卡组';

  @override
  String get deckListTitle => '全部卡组';

  @override
  String get deckCreateTitle => '新建卡组';

  @override
  String get deckRenameTitle => '重命名卡组';

  @override
  String get deckNameLabel => '卡组名称';

  @override
  String get deckNameHint => '例如：日语 N5';

  @override
  String get deckCancel => '取消';

  @override
  String get deckCreateButton => '创建';

  @override
  String get deckSaveButton => '保存';

  @override
  String get deckDeleteTitle => '删除卡组';

  @override
  String deckDeleteConfirm(Object name) {
    return '确定要删除\"$name\"吗？卡组内的所有卡片和复习记录也会删除。';
  }

  @override
  String get deckDeleteConfirmButton => '删除';

  @override
  String get deckDeleteCancel => '取消';

  @override
  String deckStats(Object count, Object due) {
    return '$count 张 · 待复习 $due';
  }

  @override
  String get deckOperationTooltip => '卡组操作';

  @override
  String get deckCloseTooltip => '关闭';

  @override
  String get deckRenameLabel => '重命名';

  @override
  String get deckDeleteLabel => '删除';

  @override
  String get deckCardCount => '牌';

  @override
  String get reviewModeNew => '学习模式';

  @override
  String get reviewModeDue => '复习模式';

  @override
  String get reviewLoadError => '队列加载失败';

  @override
  String get reviewRetry => '重试';

  @override
  String get reviewNoNewCards => '暂时没有新卡';

  @override
  String get reviewNoDueCards => '暂无待复习的卡片';

  @override
  String get reviewAllNewDone => '所有新卡都已经进入复习队列';

  @override
  String get reviewNoDueMessage => '当前范围没有到期卡片，先休息一下';

  @override
  String get reviewBackToday => '返回今日';

  @override
  String get reviewRatingForget => '忘记';

  @override
  String get reviewRatingVague => '模糊';

  @override
  String get reviewRatingFamiliar => '熟悉';

  @override
  String get reviewRatingContinue => '继续';

  @override
  String get reviewRatingRelearn => '重学';

  @override
  String reviewRated(Object label, Object interval) {
    return '已评分：$label · 下次 $interval';
  }

  @override
  String reviewRatedTitle(Object label) {
    return '已评分 $label';
  }

  @override
  String reviewRatedDetail(Object interval) {
    return '下次 $interval';
  }

  @override
  String get reviewQueue => '队列';

  @override
  String get reviewLoadingMore => '正在加载更多队列';

  @override
  String reviewOfflinePending(Object count) {
    return '离线 · $count 条评分待同步';
  }

  @override
  String get reviewCardFrontHint => '闪卡，点击回到问题面';

  @override
  String get reviewCardBackHint => '闪卡，点击翻面';

  @override
  String get reviewSessionCompleteNew => '本轮学习完成';

  @override
  String get reviewSessionCompleteDue => '今日复习完成';

  @override
  String reviewSessionStats(Object total, Object reviewed) {
    return '本次 $total 张 · 已复习 $reviewed';
  }

  @override
  String get reviewErrorQueueFailed => '队列加载失败，请检查网络后重试';

  @override
  String get reviewErrorRatingFailed => '评分失败，请检查网络后重试';

  @override
  String get startModeNew => '开始学习';

  @override
  String get startModeDue => '开始复习';

  @override
  String get startNoDecksTitle => '还没有卡组';

  @override
  String get startNoDecksMessage => '先创建一个卡组，再开始学习';

  @override
  String get startCreateDeck => '创建卡组';

  @override
  String startBadgeNew(Object count) {
    return '新卡 $count';
  }

  @override
  String startBadgeDue(Object count) {
    return '待复习 $count';
  }

  @override
  String get startFilterDue => '复习到期';

  @override
  String get cardEditorKicker => '卡片';

  @override
  String get cardEditorTitleNew => '新建卡片';

  @override
  String get cardEditorTitleEdit => '编辑卡片';

  @override
  String get cardEditorFront => '正面';

  @override
  String get cardEditorBack => '反面';

  @override
  String get cardEditorSave => '保存';

  @override
  String get cardEditorDelete => '删除';

  @override
  String get cardEditorCancel => '取消';

  @override
  String get cardImportTitle => '导入卡片';

  @override
  String get cardImportPasteJson => '粘贴 JSON 或选择 .json 文件';

  @override
  String get cardImportSelectFile => '选择文件';

  @override
  String get cardImportParse => '解析';

  @override
  String get cardImportImport => '导入';

  @override
  String get cardImportCancel => '取消';

  @override
  String get cardImportPreview => '预览';

  @override
  String get cardImportValid => '有效';

  @override
  String get cardImportInvalid => '无效';

  @override
  String get cardImportError => '错误';

  @override
  String get cardImportRow => '行';

  @override
  String get cardImportUndo => '撤销导入';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAccount => '账号';

  @override
  String get settingsEmail => '邮箱';

  @override
  String get settingsReview => '复习设置';

  @override
  String get settingsRefreshTime => '每日刷新时间';

  @override
  String get settingsRefreshSubtitle => '过此时间后计入新的一天';

  @override
  String get settingsData => '数据管理';

  @override
  String get settingsExport => '导出数据';

  @override
  String get settingsExportSubtitle => '保存全部卡组、卡片与复习记录';

  @override
  String get settingsImport => '导入数据';

  @override
  String get settingsImportSubtitle => '从备份文件覆盖恢复';

  @override
  String get settingsForceServer => '以服务器为准';

  @override
  String get settingsForceServerSubtitle => '丢弃待同步评分并重新拉取服务器数据';

  @override
  String get settingsForceServerTitle => '以服务器为准';

  @override
  String get settingsForceServerContent => '这会丢弃所有未同步的离线评分，并用服务器数据覆盖本地。确定继续吗？';

  @override
  String get settingsForceServerConfirm => '确定覆盖';

  @override
  String get settingsForceServerCancel => '取消';

  @override
  String get settingsImportTitle => '导入数据';

  @override
  String get settingsImportContent => '导入将覆盖当前所有数据，此操作不可逆。确定要继续吗？';

  @override
  String get settingsImportConfirm => '确定导入';

  @override
  String get settingsImportCancel => '取消';

  @override
  String settingsImportSuccess(Object decks, Object cards, Object logs) {
    return '数据已恢复：$decks 个卡组，$cards 张卡片，$logs 条记录';
  }

  @override
  String get settingsExportFail => '导出失败，请检查网络后重试';

  @override
  String get settingsImportFail => '导入失败，请检查网络或备份文件后重试';

  @override
  String get settingsImportReadFail => '读取备份失败，请确认文件格式正确后重试';

  @override
  String get settingsSyncFail => '同步失败，请检查网络后重试';

  @override
  String get settingsLogout => '退出登录';

  @override
  String get settingsLanguage => '语言';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get statsTitle => '统计';

  @override
  String get statsOverview => '概览';

  @override
  String get statsTotalCards => '总卡片数';

  @override
  String get statsTotalDecks => '总卡组数';

  @override
  String get statsDueToday => '今日到期';

  @override
  String get statsReviewedToday => '今日复习';

  @override
  String get statsLearnedToday => '今日新学';

  @override
  String get statsMastered => '已掌握';

  @override
  String get statsLearning => '学习中';

  @override
  String get statsTrend => '趋势';

  @override
  String get statsDeckStats => '卡组统计';

  @override
  String get statsStageDistribution => '阶段分布';

  @override
  String get statsNewCards => '新卡片';

  @override
  String get cardListTitle => '卡片';

  @override
  String get cardListFilterAll => '全部';

  @override
  String get cardListFilterDue => '到期';

  @override
  String get cardListFilterLearning => '学习中';

  @override
  String get cardListFilterNew => '新卡';

  @override
  String get cardListSearch => '搜索';

  @override
  String get cardListBatchDelete => '批量删除';

  @override
  String get cardListNoCards => '暂无卡片';

  @override
  String cardListConfirmDelete(Object count) {
    return '删除 $count 张卡片？';
  }

  @override
  String get errorLoadFailed => '加载失败，请检查网络后重试';

  @override
  String get errorSaveFailed => '保存失败，请检查网络后重试';

  @override
  String get errorRetry => '重试';

  @override
  String get themeIntervalRelearn => '重学';

  @override
  String themeIntervalDays(Object days) {
    return '$days 天';
  }

  @override
  String get themeIntervalDay => '1 天';

  @override
  String get themeStageNew => '新卡';

  @override
  String get cardImportFrontEmpty => '正面内容不能为空';

  @override
  String get cardImportFrontMustBeString => '正面内容必须是字符串';

  @override
  String get cardImportBackEmpty => '反面内容不能为空';

  @override
  String get cardImportBackMustBeString => '反面内容必须是字符串';

  @override
  String get cardImportCardMustBeObject => '卡片必须是对象';

  @override
  String get backendAuthRegisterSuccess => '注册成功';

  @override
  String get backendAuthLoginSuccess => '登录成功';

  @override
  String get backendAuthLogoutSuccess => '已登出';

  @override
  String get backendAuthInviteRequired => '请输入邀请码';

  @override
  String get backendAuthInviteInvalid => '邀请码无效';

  @override
  String get backendAuthEmailRegistered => '邮箱已被注册';

  @override
  String get backendAuthEmailPasswordWrong => '邮箱或密码错误';

  @override
  String get backendAuthUnauthorized => '未登录或Token已过期';

  @override
  String get backendDeckNotfound => '卡组不存在';

  @override
  String get backendDeckCreated => '卡组已创建';

  @override
  String get backendDeckUpdated => '卡组已更新';

  @override
  String get backendDeckDeleted => '卡组已删除';

  @override
  String get backendCardNotfound => '卡片不存在';

  @override
  String get backendCardCreated => '卡片已创建';

  @override
  String get backendCardUpdated => '卡片已更新';

  @override
  String get backendCardDeleted => '卡片已删除';

  @override
  String get backendCardIdListEmpty => '卡片 ID 列表不能为空';

  @override
  String get backendCardSearchTooLong => '搜索词不能超过 100 个字符';

  @override
  String get backendCardFrontEmpty => '正面内容不能为空';

  @override
  String get backendCardBackEmpty => '反面内容不能为空';

  @override
  String get backendCardImportJsonEmpty => 'JSON 内容不能为空';

  @override
  String get backendCardImportJsonTooLarge => 'JSON 内容过大，最多支持 2MB';

  @override
  String get backendCardImportJsonInvalid => 'JSON 格式不正确';

  @override
  String get backendCardImportJsonMustBeArray => 'JSON 必须是数组';

  @override
  String get backendCardImportJsonArrayEmpty => 'JSON 数组不能为空';

  @override
  String backendCardImportTooMany(Object count) {
    return '单次最多导入 $count 张卡片';
  }

  @override
  String get backendCardImportListEmpty => '卡片列表不能为空';

  @override
  String get backendCardImportDataEmpty => '卡片数据不能为空';

  @override
  String get backendReviewSessionNotfound => '复习会话不存在';

  @override
  String get backendReviewSessionExpired => '复习会话已过期';

  @override
  String get backendReviewSessionClosed => '复习会话已关闭';

  @override
  String get backendReviewRatingInvalid => '无效的评分';

  @override
  String get backendReviewConflictRequest => '请求已使用，但卡片或评分不一致';

  @override
  String get backendReviewConflictVersion => '卡片状态已变化，请刷新后重新评分';

  @override
  String get backendReviewCardNotfound => '卡片不存在';

  @override
  String get backendSettingsNotfound => '用户不存在';

  @override
  String get backendSettingsUpdated => '设置已更新';

  @override
  String get backendStatsDeckNotfound => '卡组不存在';

  @override
  String get backendBackupCreated => '备份已创建';

  @override
  String get backendBackupDataEmpty => '备份数据不能为空';

  @override
  String get backendBackupImported => '数据已恢复';

  @override
  String get backendSyncUserNotfound => '用户不存在';

  @override
  String get backendServerError => '服务器内部错误';

  @override
  String get backendServerResourceNotfound => '资源不存在';

  @override
  String get settingsLogs => '操作日志';

  @override
  String get settingsLogsSubtitle => '查看脱敏日志，辅助诊断问题';

  @override
  String get logTitle => '操作日志';

  @override
  String get logFilterAll => '全部';

  @override
  String get logLevelInfo => 'INFO';

  @override
  String get logLevelWarn => 'WARN';

  @override
  String get logLevelError => 'ERROR';

  @override
  String get logCategoryAuth => '认证';

  @override
  String get logCategoryReview => '复习';

  @override
  String get logCategoryCard => '卡片';

  @override
  String get logCategoryDeck => '卡组';

  @override
  String get logCategoryBackup => '备份';

  @override
  String get logCategorySettings => '设置';

  @override
  String get logCategorySystem => '系统';

  @override
  String get logEmpty => '暂无日志';

  @override
  String get logDetails => '详情';

  @override
  String get logNoMore => '没有更多了';

  @override
  String get logLoadMore => '加载更多';

  @override
  String get logLevel => '级别';

  @override
  String get logCategory => '分类';

  @override
  String get logTime => '时间';

  @override
  String get logMessage => '消息';

  @override
  String get logDiagnostics => '诊断';
}
