package top.kariscode.karisreview.card.repository;

/**
 * 卡片查询谓词单一事实源（架构评审候选 3，2026-08）。
 *
 * due/new 队列与统计口径只有两种，此前在 CardRepository 复制 9 处
 * （JPQL + native SQL）并在前端 offline_repository.dart 等价重写 10+ 处，
 * 改口径漏改即静默错查。本类集中声明，@Query 一律拼接常量；
 * 前端离线过滤收敛为 offline_repository 的 _isNewCard/_isDueCard，
 * 两端 javadoc/注释互相引用。
 *
 * 注意：JPQL 用实体字段（c.xxx），native SQL 用 cards 表列名（xxx）。
 */
public final class CardQueryPredicates {

    private CardQueryPredicates() {
    }

    // 队列分支常量：队列查询按分支拼接（@Query 不再手写谓词，2026-08 架构评审 B3 闭合）。
    // 完整口径常量由分支常量组成，改口径只改一处。

    /** 复习队列-非重学分支（JPQL）：非重学卡（到期判定由查询的 nextReviewDate 条件负责）。 */
    public static final String DUE_BASE_JPQL = "c.learningMode = false";

    /** 复习队列-重学分支（JPQL）：REVIEW/null 来源重学卡（复习阶段失败，归复习队列）。 */
    public static final String DUE_RELEARNING_JPQL =
            "c.learningMode = true AND (c.learningOrigin = 'REVIEW' OR c.learningOrigin IS NULL)";

    /** 学新队列-待学分支（JPQL）：待学新卡（stage=0 且非重学）。 */
    public static final String NEW_BASE_JPQL = "c.stage = 0 AND c.learningMode = false";

    /** 学新队列-重学分支（JPQL）：NEW 来源重学卡（学新阶段失败，归学新队列）。 */
    public static final String NEW_RELEARNING_JPQL =
            "c.learningMode = true AND c.learningOrigin = 'NEW'";

    /** 学新队列口径（JPQL）：待学新卡 + 学新阶段重学卡。
     *  对应前端 _isNewCard；统计口径 new_cards 同此。 */
    public static final String NEW_QUEUE_JPQL =
            "(" + NEW_BASE_JPQL + ") OR (" + NEW_RELEARNING_JPQL + ")";

    /** 学新队列口径（native SQL，cards 表列名版）。 */
    public static final String NEW_QUEUE_SQL =
            "(NOT learning_mode AND stage = 0) "
                    + "OR (learning_mode AND learning_origin = 'NEW')";

    /** 复习队列/统计口径（JPQL）：到期卡且非学新阶段重学——非重学卡，或 origin 为 REVIEW/null。
     *  对应前端 _isDueCard；统计口径 due_today/due_stage_distribution 同此，
     *  卡片列表 filter=due 亦须用此（2026-08 修复：此前派生查询未排除 NEW 重学，与计数口径不一致）。 */
    public static final String DUE_EXCLUDING_NEW_JPQL =
            "(" + DUE_BASE_JPQL + " OR c.learningOrigin = 'REVIEW' OR c.learningOrigin IS NULL)";

    /** 复习队列/统计口径（native SQL，cards 表列名版）。 */
    public static final String DUE_EXCLUDING_NEW_SQL =
            "(NOT learning_mode "
                    + "OR learning_origin = 'REVIEW' OR learning_origin IS NULL)";
}
