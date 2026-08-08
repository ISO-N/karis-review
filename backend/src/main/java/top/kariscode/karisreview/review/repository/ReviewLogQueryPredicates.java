package top.kariscode.karisreview.review.repository;

/**
 * 复习日志统计谓词单一事实源（架构评审 B2，2026-08）。
 *
 * 「今日复习/今日新学」口径此前在 ReviewLogRepository 复制多份
 * （countReviewedToday / countReviewedTodayForDeck 的 JPQL 字面量、
 * findDailyTrend 的 native SQL 再写一遍），改口径需同时动 3+ 处，
 * 与 CardQueryPredicates（卡片口径）形成反差。本类集中声明，
 * @Query 一律拼接常量。
 *
 * 注意：JPQL 用 ReviewLog 实体字段（r.xxx），native SQL 用 review_logs 表列名。
 */
public final class ReviewLogQueryPredicates {

    private ReviewLogQueryPredicates() {
    }

    /** 今日复习口径（JPQL）：非新卡评分且非「学新阶段重学」评分（origin <> 'NEW'）。
     *  即只统计到期卡复习 + 复习阶段重学（同卡片口径 DUE_EXCLUDING_NEW）。 */
    public static final String REVIEWED_TODAY_JPQL =
            "r.newCard = false "
                    + "AND (r.learningOrigin IS NULL OR r.learningOrigin <> 'NEW')";

    /** 今日复习口径（native SQL，review_logs 表列名版）。 */
    public static final String REVIEWED_TODAY_SQL =
            "is_new_card = FALSE AND (learning_origin IS NULL OR learning_origin <> 'NEW')";

    /** 今日新学口径（JPQL）：新卡评分且 FAMILIAR。 */
    public static final String LEARNED_TODAY_JPQL =
            "r.newCard = true AND r.rating = 'FAMILIAR'";

    /** 今日新学口径（native SQL，review_logs 表列名版）。 */
    public static final String LEARNED_TODAY_SQL =
            "is_new_card = TRUE AND rating = 'FAMILIAR'";
}
