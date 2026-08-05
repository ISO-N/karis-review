package top.kariscode.karisreview.stats.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.stats.entity.DailyReviewStats;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DailyReviewStatsRepository extends JpaRepository<DailyReviewStats, UUID> {

    Optional<DailyReviewStats> findByUserIdAndStatDateAndDeckId(UUID userId, LocalDate statDate, UUID deckId);

    Optional<DailyReviewStats> findByUserIdAndStatDateAndDeckIdIsNull(UUID userId, LocalDate statDate);

    List<DailyReviewStats> findByUserIdAndStatDateBetweenOrderByStatDateAsc(
            UUID userId, LocalDate start, LocalDate end);

    /**
     * 增量 upsert：复习/新学计数 +1（事件驱动，ReviewLogged 事件消费时调用）。
     * 全量行（deck_id IS NULL）依赖部分唯一索引 upsert。
     */
    @Modifying
    @Query(value = "INSERT INTO daily_review_stats (id, user_id, stat_date, deck_id, reviewed_count, learned_count, unique_cards, updated_at) " +
                   "VALUES (gen_random_uuid(), :userId, :statDate, :deckId, :reviewedInc, :learnedInc, :uniqueInc, NOW()) " +
                   "ON CONFLICT (user_id, stat_date, deck_id) DO UPDATE SET " +
                   "reviewed_count = daily_review_stats.reviewed_count + EXCLUDED.reviewed_count, " +
                   "learned_count = daily_review_stats.learned_count + EXCLUDED.learned_count, " +
                   "unique_cards = daily_review_stats.unique_cards + EXCLUDED.unique_cards, " +
                   "updated_at = NOW()",
           nativeQuery = true)
    int upsertIncrement(@Param("userId") UUID userId,
                        @Param("statDate") LocalDate statDate,
                        @Param("deckId") UUID deckId,
                        @Param("reviewedInc") int reviewedInc,
                        @Param("learnedInc") int learnedInc,
                        @Param("uniqueInc") int uniqueInc);

    /** 用户全量汇总行（deck_id IS NULL）的增量 upsert。 */
    @Modifying
    @Query(value = "INSERT INTO daily_review_stats (id, user_id, stat_date, deck_id, reviewed_count, learned_count, unique_cards, updated_at) " +
                   "VALUES (gen_random_uuid(), :userId, :statDate, NULL, :reviewedInc, :learnedInc, :uniqueInc, NOW()) " +
                   "ON CONFLICT (user_id, stat_date) WHERE deck_id IS NULL DO UPDATE SET " +
                   "reviewed_count = daily_review_stats.reviewed_count + EXCLUDED.reviewed_count, " +
                   "learned_count = daily_review_stats.learned_count + EXCLUDED.learned_count, " +
                   "unique_cards = daily_review_stats.unique_cards + EXCLUDED.unique_cards, " +
                   "updated_at = NOW()",
           nativeQuery = true)
    int upsertIncrementAll(@Param("userId") UUID userId,
                           @Param("statDate") LocalDate statDate,
                           @Param("reviewedInc") int reviewedInc,
                           @Param("learnedInc") int learnedInc,
                           @Param("uniqueInc") int uniqueInc);

    /** 重算前清理某一业务日的旧聚合行。 */
    @Modifying
    @Query(value = "DELETE FROM daily_review_stats WHERE user_id = :userId AND stat_date = :statDate " +
                   "AND (:deckId IS NULL OR deck_id = :deckId)",
           nativeQuery = true)
    int deleteForDay(@Param("userId") UUID userId,
                     @Param("statDate") LocalDate statDate,
                     @Param("deckId") UUID deckId);

    /**
     * 全量重算某一业务日：按卡组维度从 review_logs 重新聚合（幂等，修复增量漂移）。
     * 调用方需传入业务日窗口（基于用户 refresh_time 的 [start, end)）。
     */
    @Modifying
    @Query(value = "INSERT INTO daily_review_stats (id, user_id, stat_date, deck_id, reviewed_count, learned_count, unique_cards, updated_at) " +
                   "SELECT gen_random_uuid(), :userId, :statDate, c.deck_id, " +
                   "       COUNT(*) FILTER (WHERE r.new_card = FALSE), " +
                   "       COUNT(*) FILTER (WHERE r.new_card = TRUE AND r.rating = 'FAMILIAR'), " +
                   "       COUNT(DISTINCT r.card_id), NOW() " +
                   "FROM review_logs r JOIN cards c ON c.id = r.card_id " +
                   "WHERE r.user_id = :userId AND r.reviewed_at >= :start AND r.reviewed_at < :end " +
                   "GROUP BY c.deck_id",
           nativeQuery = true)
    int rebuildFromLogs(@Param("userId") UUID userId,
                        @Param("statDate") LocalDate statDate,
                        @Param("start") java.time.LocalDateTime start,
                        @Param("end") java.time.LocalDateTime end);

    /** 重算后生成用户全量汇总行（deck_id IS NULL）。 */
    @Modifying
    @Query(value = "INSERT INTO daily_review_stats (id, user_id, stat_date, deck_id, reviewed_count, learned_count, unique_cards, updated_at) " +
                   "SELECT gen_random_uuid(), :userId, :statDate, NULL, " +
                   "       COUNT(*) FILTER (WHERE r.new_card = FALSE), " +
                   "       COUNT(*) FILTER (WHERE r.new_card = TRUE AND r.rating = 'FAMILIAR'), " +
                   "       COUNT(DISTINCT r.card_id), NOW() " +
                   "FROM review_logs r " +
                   "WHERE r.user_id = :userId AND r.reviewed_at >= :start AND r.reviewed_at < :end",
           nativeQuery = true)
    int rebuildAllFromLogs(@Param("userId") UUID userId,
                           @Param("statDate") LocalDate statDate,
                           @Param("start") java.time.LocalDateTime start,
                           @Param("end") java.time.LocalDateTime end);
}
