package top.kariscode.karisreview.card.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import jakarta.persistence.LockModeType;
import top.kariscode.karisreview.card.entity.Card;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.card.entity.Card;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CardRepository extends JpaRepository<Card, UUID> {

    List<Card> findByDeckIdOrderByCreatedAtAsc(UUID deckId);
    Page<Card> findByDeckIdOrderByCreatedAtAsc(UUID deckId, Pageable pageable);
    Page<Card> findByDeckIdAndLearningModeTrueOrderByCreatedAtAsc(UUID deckId, Pageable pageable);
    @Query("SELECT c FROM Card c WHERE c.deckId = :deckId " +
           "AND ((c.learningMode = false AND c.stage = 0) " +
           "     OR (c.learningMode = true AND c.learningOrigin = 'NEW')) " +
           "ORDER BY c.createdAt DESC")
    Page<Card> findNewByDeckIdOrderByCreatedAtDesc(@Param("deckId") UUID deckId, Pageable pageable);
    Page<Card> findByDeckIdAndNextReviewDateNotNullAndNextReviewDateLessThanEqualOrderByNextReviewDateAsc(
            UUID deckId, LocalDate today, Pageable pageable);
    @Query("SELECT c FROM Card c WHERE c.deckId = :deckId " +
           "AND (LOWER(c.front) LIKE LOWER(:pattern) ESCAPE '\\' " +
           "OR LOWER(c.back) LIKE LOWER(:pattern) ESCAPE '\\') " +
           "ORDER BY c.createdAt ASC")
    Page<Card> searchByDeckIdOrderByCreatedAtAsc(@Param("deckId") UUID deckId,
                                                @Param("pattern") String pattern,
                                                Pageable pageable);
    @Query("SELECT c FROM Card c WHERE c.deckId = :deckId " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today " +
           "AND (LOWER(c.front) LIKE LOWER(:pattern) ESCAPE '\\' " +
           "OR LOWER(c.back) LIKE LOWER(:pattern) ESCAPE '\\') " +
           "ORDER BY c.nextReviewDate ASC")
    Page<Card> searchByDeckIdAndNextReviewDateNotNullAndNextReviewDateLessThanEqualOrderByNextReviewDateAsc(
            UUID deckId, LocalDate today, String pattern, Pageable pageable);
    @Query("SELECT c FROM Card c WHERE c.deckId = :deckId " +
           "AND c.learningMode = true " +
           "AND (LOWER(c.front) LIKE LOWER(:pattern) ESCAPE '\\' " +
           "OR LOWER(c.back) LIKE LOWER(:pattern) ESCAPE '\\') " +
           "ORDER BY c.createdAt ASC")
    Page<Card> searchByDeckIdAndLearningModeTrueOrderByCreatedAtAsc(@Param("deckId") UUID deckId,
                                                                   @Param("pattern") String pattern,
                                                                   Pageable pageable);
    @Query("SELECT c FROM Card c WHERE c.deckId = :deckId " +
           "AND ((c.learningMode = false AND c.stage = 0) " +
           "     OR (c.learningMode = true AND c.learningOrigin = 'NEW')) " +
           "AND (LOWER(c.front) LIKE LOWER(:pattern) ESCAPE '\\' " +
           "OR LOWER(c.back) LIKE LOWER(:pattern) ESCAPE '\\') " +
           "ORDER BY c.createdAt DESC")
    Page<Card> searchNewByDeckIdOrderByCreatedAtDesc(@Param("deckId") UUID deckId,
                                                    @Param("pattern") String pattern,
                                                    Pageable pageable);
    Optional<Card> findByIdAndUserId(UUID id, UUID userId);
    List<Card> findByIdInAndUserId(List<UUID> ids, UUID userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM Card c WHERE c.id = :id AND c.userId = :userId")
    Optional<Card> findByIdAndUserIdForUpdate(@Param("id") UUID id, @Param("userId") UUID userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM Card c WHERE c.id IN :ids AND c.userId = :userId")
    List<Card> findByIdInAndUserIdForUpdate(@Param("ids") List<UUID> ids, @Param("userId") UUID userId);

    List<Card> findByUserId(UUID userId);
    long countByDeckId(UUID deckId);
    long countByUserId(UUID userId);
    long countByDeckIdAndLearningModeTrue(UUID deckId);
    long countByDeckIdAndStageGreaterThanEqual(UUID deckId, int stage);
    long countByDeckIdAndStage(UUID deckId, int stage);
    long countByDeckIdAndStageAndLearningModeFalse(UUID deckId, int stage);
    @Query("SELECT COUNT(c) FROM Card c WHERE c.userId = :userId " +
           "AND ((c.stage = 0 AND c.learningMode = false) " +
           "     OR (c.learningMode = true AND c.learningOrigin = 'NEW'))")
    long countNewByUserId(@Param("userId") UUID userId);

    @Query("SELECT COUNT(c) FROM Card c WHERE c.deckId = :deckId " +
           "AND ((c.stage = 0 AND c.learningMode = false) " +
           "     OR (c.learningMode = true AND c.learningOrigin = 'NEW'))")
    long countNewByDeckId(@Param("deckId") UUID deckId);

    @Query("SELECT COUNT(c) FROM Card c WHERE c.deckId = :deckId " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today " +
           "AND (c.learningMode = false OR c.learningOrigin = 'REVIEW' OR c.learningOrigin IS NULL)")
    int countDueByDeckId(@Param("deckId") UUID deckId, @Param("today") LocalDate today);

    @Query("SELECT c.stage, COUNT(c) FROM Card c WHERE c.userId = :userId GROUP BY c.stage")
    List<Object[]> countByStageGrouped(@Param("userId") UUID userId);

    @Query("SELECT c.stage, COUNT(c) FROM Card c WHERE c.userId = :userId " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today " +
           "AND (c.learningMode = false OR c.learningOrigin = 'REVIEW' OR c.learningOrigin IS NULL) " +
           "GROUP BY c.stage")
    List<Object[]> countDueByStageGrouped(@Param("userId") UUID userId, @Param("today") LocalDate today);

    @Query("SELECT c.stage, COUNT(c) FROM Card c WHERE c.deckId = :deckId GROUP BY c.stage")
    List<Object[]> countByStageGroupedByDeck(@Param("deckId") UUID deckId);

    @Query("SELECT c.stage, COUNT(c) FROM Card c WHERE c.deckId = :deckId " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today " +
           "AND (c.learningMode = false OR c.learningOrigin = 'REVIEW' OR c.learningOrigin IS NULL) " +
           "GROUP BY c.stage")
    List<Object[]> countDueByStageGroupedByDeck(@Param("deckId") UUID deckId, @Param("today") LocalDate today);

    @Query("SELECT c FROM Card c WHERE c.userId = :userId " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today " +
           "AND c.learningMode = false " +
           "AND (:deckId IS NULL OR c.deckId = :deckId) " +
           // 逾期优先（逾期天数降序）在数学上等价于 next_review_date 升序，
           // 直接按列排序可命中 idx_cards_next_review 部分索引，消除 Sort 节点。
           "ORDER BY c.nextReviewDate ASC")
    List<Card> findDueCards(@Param("userId") UUID userId,
                            @Param("today") LocalDate today,
                            @Param("deckId") UUID deckId);

    @Query("SELECT c FROM Card c WHERE c.userId = :userId " +
           "AND c.stage = 0 AND c.learningMode = false " +
           "AND (:deckId IS NULL OR c.deckId = :deckId) " +
           "ORDER BY c.createdAt ASC")
    List<Card> findNewCards(@Param("userId") UUID userId,
                            @Param("deckId") UUID deckId);

    @Query("SELECT c FROM Card c WHERE c.userId = :userId " +
           "AND c.learningMode = true " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today " +
           "AND c.learningOrigin = 'NEW' " +
           "AND (:deckId IS NULL OR c.deckId = :deckId) " +
           "ORDER BY c.nextReviewDate ASC")
    List<Card> findLearningModeCardsForNew(@Param("userId") UUID userId,
                                           @Param("today") LocalDate today,
                                           @Param("deckId") UUID deckId);

    @Query("SELECT c FROM Card c WHERE c.userId = :userId " +
           "AND c.learningMode = true " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today " +
           "AND (c.learningOrigin = 'REVIEW' OR c.learningOrigin IS NULL) " +
           "AND (:deckId IS NULL OR c.deckId = :deckId) " +
           "ORDER BY c.nextReviewDate ASC")
    List<Card> findLearningModeCardsForReview(@Param("userId") UUID userId,
                                              @Param("today") LocalDate today,
                                              @Param("deckId") UUID deckId);

    @Query("SELECT COUNT(c) FROM Card c WHERE c.userId = :userId " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today")
    long countDueToday(@Param("userId") UUID userId, @Param("today") LocalDate today);

    long countByUserIdAndStageGreaterThanEqual(UUID userId, int stage);
    long countByUserIdAndStageLessThan(UUID userId, int stage);

    @Query("SELECT COUNT(c) FROM Card c WHERE c.userId = :userId " +
           "AND c.learningMode = true")
    long countByLearningMode(@Param("userId") UUID userId);

    /**
     * 用户级概览聚合：一次查询产出全部计数与分布，替代原来的 7+ 条独立 COUNT。
     * 配合 idx_cards_user_stage_learning 复合索引可走 Index Only Scan。
     * 列顺序: stage, total, learning_cards(stage<5), mastered(stage>=5 非学习),
     *         new_cards(待学新卡 + 学新阶段重学卡, 即学新队列规模),
     *         due(到期卡 + 复习阶段重学卡, 即复习队列规模; 学新阶段重学卡不计入)
     */
    @Query(value = "SELECT stage, COUNT(*) AS total, " +
                   "COUNT(*) FILTER (WHERE stage < 5) AS learning_cards, " +
                   "COUNT(*) FILTER (WHERE NOT learning_mode AND stage >= 5) AS mastered, " +
                   "COUNT(*) FILTER (WHERE (stage = 0 AND NOT learning_mode) " +
                   "                  OR (learning_mode AND learning_origin = 'NEW')) AS new_cards, " +
                   "COUNT(*) FILTER (WHERE next_review_date IS NOT NULL " +
                   "AND next_review_date <= :today " +
                   "AND (NOT learning_mode OR learning_origin = 'REVIEW' OR learning_origin IS NULL)) AS due " +
                   "FROM cards WHERE user_id = :userId GROUP BY stage",
           nativeQuery = true)
    List<Object[]> aggregateOverviewStats(@Param("userId") UUID userId, @Param("today") LocalDate today);
}