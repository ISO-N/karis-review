package top.kariscode.karisreview.review.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.review.entity.ReviewLog;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface ReviewLogRepository extends JpaRepository<ReviewLog, UUID> {

    List<ReviewLog> findByUserIdOrderByReviewedAtDesc(UUID userId);

    @Query("SELECT COUNT(r) FROM ReviewLog r WHERE r.userId = :userId " +
           "AND r.reviewedAt >= :startOfDay AND r.reviewedAt < :endOfDay " +
           "AND r.newCard = false")
    long countReviewedToday(@Param("userId") UUID userId,
                            @Param("startOfDay") LocalDateTime startOfDay,
                            @Param("endOfDay") LocalDateTime endOfDay);
    @Query("SELECT COUNT(r) FROM ReviewLog r WHERE r.userId = :userId " +
           "AND r.reviewedAt >= :startOfDay AND r.reviewedAt < :endOfDay " +
           "AND r.newCard = true AND r.rating = 'FAMILIAR'")
    long countLearnedToday(@Param("userId") UUID userId,
                           @Param("startOfDay") LocalDateTime startOfDay,
                           @Param("endOfDay") LocalDateTime endOfDay);
    @Query("SELECT r FROM ReviewLog r WHERE r.userId = :userId " +
           "AND r.reviewedAt >= :start " +
           "ORDER BY r.reviewedAt ASC")
    List<ReviewLog> findByUserIdAndReviewedAtAfter(@Param("userId") UUID userId,
                                                    @Param("start") LocalDateTime start);

    @Query("SELECT FUNCTION('DATE', r.reviewedAt) as reviewDate, " +
           "SUM(CASE WHEN r.newCard = false THEN 1 ELSE 0 END) as cnt, " +
           "SUM(CASE WHEN r.newCard = true AND r.rating = 'FAMILIAR' THEN 1 ELSE 0 END) as learned " +
           "FROM ReviewLog r WHERE r.userId = :userId " +
           "AND r.reviewedAt >= :start " +
           "GROUP BY FUNCTION('DATE', r.reviewedAt) " +
           "ORDER BY FUNCTION('DATE', r.reviewedAt) ASC")
    List<Object[]> findDailyTrend(@Param("userId") UUID userId,
                                  @Param("start") LocalDateTime start);
    @Query("SELECT COUNT(r) FROM ReviewLog r WHERE r.userId = :userId " +
           "AND r.reviewedAt >= :startOfDay AND r.reviewedAt < :endOfDay " +
           "AND r.newCard = false " +
           "AND r.cardId IN (SELECT c.id FROM Card c WHERE c.deckId = :deckId)")
    long countReviewedTodayForDeck(@Param("userId") UUID userId,
                                   @Param("deckId") UUID deckId,
                                   @Param("startOfDay") LocalDateTime startOfDay,
                                   @Param("endOfDay") LocalDateTime endOfDay);
}