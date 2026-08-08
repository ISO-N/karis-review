package top.kariscode.karisreview.review.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.review.entity.ReviewLog;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ReviewLogRepository extends JpaRepository<ReviewLog, UUID> {

    List<ReviewLog> findByUserIdOrderByReviewedAtDesc(UUID userId);

    Page<ReviewLog> findByUserIdOrderByReviewedAtDesc(UUID userId, Pageable pageable);

    Optional<ReviewLog> findByUserIdAndClientRequestId(UUID userId, String clientRequestId);

    @Query("SELECT r FROM ReviewLog r WHERE r.userId = :userId AND r.clientRequestId IN :ids")
    List<ReviewLog> findByUserIdAndClientRequestIdIn(@Param("userId") UUID userId,
                                                     @Param("ids") List<String> ids);

    @Query("SELECT COUNT(r) FROM ReviewLog r WHERE r.userId = :userId " +
           "AND r.reviewedAt >= :startOfDay AND r.reviewedAt < :endOfDay " +
           "AND " + ReviewLogQueryPredicates.REVIEWED_TODAY_JPQL)
    long countReviewedToday(@Param("userId") UUID userId,
                            @Param("startOfDay") LocalDateTime startOfDay,
                            @Param("endOfDay") LocalDateTime endOfDay);

    @Query("SELECT COUNT(r) FROM ReviewLog r WHERE r.userId = :userId " +
           "AND r.reviewedAt >= :startOfDay AND r.reviewedAt < :endOfDay " +
           "AND " + ReviewLogQueryPredicates.LEARNED_TODAY_JPQL)
    long countLearnedToday(@Param("userId") UUID userId,
                           @Param("startOfDay") LocalDateTime startOfDay,
                           @Param("endOfDay") LocalDateTime endOfDay);

    /**
     * 趋势聚合：按“业务日”分组（reviewed_at 减去用户刷新点后取日期，与
     * DateUtils.calculateToday 口径一致——刷新点之前的日志归到前一天），
     * 聚合下推到数据库，避免把全量 ReviewLog 实体加载进 JVM 内存逐条统计。
     * 返回行：[业务日, 复习次数, 新学次数(新卡且 FAMILIAR)]。
     * 复习次数 = 非新卡评分且非「学新阶段重学」评分（REVIEWED_TODAY_SQL），
     * 即今日复习只统计到期卡复习与复习阶段重学。
     */
    @Query(value = "SELECT (reviewed_at - CAST(:refreshTime AS time))::date AS review_date, "
            + "SUM(CASE WHEN " + ReviewLogQueryPredicates.REVIEWED_TODAY_SQL
            + " THEN 1 ELSE 0 END) AS reviewed_cnt, "
            + "SUM(CASE WHEN " + ReviewLogQueryPredicates.LEARNED_TODAY_SQL
            + " THEN 1 ELSE 0 END) AS learned_cnt "
            + "FROM review_logs "
            + "WHERE user_id = :userId AND reviewed_at >= :start "
            + "GROUP BY 1 ORDER BY 1", nativeQuery = true)
    List<Object[]> findDailyTrend(@Param("userId") UUID userId,
                                  @Param("start") LocalDateTime start,
                                  @Param("refreshTime") LocalTime refreshTime);

    @Query("SELECT COUNT(r) FROM ReviewLog r WHERE r.userId = :userId " +
           "AND r.reviewedAt >= :startOfDay AND r.reviewedAt < :endOfDay " +
           "AND " + ReviewLogQueryPredicates.REVIEWED_TODAY_JPQL + " " +
           "AND r.cardId IN (SELECT c.id FROM Card c WHERE c.deckId = :deckId)")
    long countReviewedTodayForDeck(@Param("userId") UUID userId,
                                   @Param("deckId") UUID deckId,
                                   @Param("startOfDay") LocalDateTime startOfDay,
                                   @Param("endOfDay") LocalDateTime endOfDay);
}
