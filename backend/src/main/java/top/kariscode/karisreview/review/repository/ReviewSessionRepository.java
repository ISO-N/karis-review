package top.kariscode.karisreview.review.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.review.entity.ReviewSession;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ReviewSessionRepository extends JpaRepository<ReviewSession, UUID> {

    Optional<ReviewSession> findByIdAndUserId(UUID id, UUID userId);

    @Modifying
    @Query("DELETE FROM ReviewSession s WHERE s.expiresAt < :now")
    int deleteExpired(@Param("now") LocalDateTime now);
}
