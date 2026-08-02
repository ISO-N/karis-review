package top.kariscode.karisreview.card.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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
    Page<Card> findByDeckIdAndNextReviewDateNotNullAndNextReviewDateLessThanEqualOrderByNextReviewDateAsc(
            UUID deckId, LocalDate today, Pageable pageable);
    Optional<Card> findByIdAndUserId(UUID id, UUID userId);
    long countByDeckId(UUID deckId);
    long countByUserId(UUID userId);
    long countByDeckIdAndLearningModeTrue(UUID deckId);
    long countByDeckIdAndStageGreaterThanEqual(UUID deckId, int stage);
    long countByDeckIdAndStage(UUID deckId, int stage);
    long countByDeckIdAndStageAndLearningModeFalse(UUID deckId, int stage);

    @Query("SELECT COUNT(c) FROM Card c WHERE c.deckId = :deckId " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today")
    int countDueByDeckId(@Param("deckId") UUID deckId, @Param("today") LocalDate today);

    @Query("SELECT c.stage, COUNT(c) FROM Card c WHERE c.userId = :userId GROUP BY c.stage")
    List<Object[]> countByStageGrouped(@Param("userId") UUID userId);

    @Query("SELECT c.stage, COUNT(c) FROM Card c WHERE c.userId = :userId " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today GROUP BY c.stage")
    List<Object[]> countDueByStageGrouped(@Param("userId") UUID userId, @Param("today") LocalDate today);

    @Query("SELECT c.stage, COUNT(c) FROM Card c WHERE c.deckId = :deckId GROUP BY c.stage")
    List<Object[]> countByStageGroupedByDeck(@Param("deckId") UUID deckId);

    @Query("SELECT c.stage, COUNT(c) FROM Card c WHERE c.deckId = :deckId " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today GROUP BY c.stage")
    List<Object[]> countDueByStageGroupedByDeck(@Param("deckId") UUID deckId, @Param("today") LocalDate today);

    @Query("SELECT c FROM Card c WHERE c.userId = :userId " +
           "AND c.nextReviewDate IS NOT NULL AND c.nextReviewDate <= :today " +
           "AND c.learningMode = false " +
           "AND (:deckId IS NULL OR c.deckId = :deckId) " +
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
           "AND (:deckId IS NULL OR c.deckId = :deckId) " +
           "ORDER BY c.nextReviewDate ASC")
    List<Card> findLearningModeCards(@Param("userId") UUID userId,
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
}