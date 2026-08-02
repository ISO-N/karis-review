package top.kariscode.karisreview.review.repository;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.review.entity.ReviewQueueItem;

import java.util.List;
import java.util.UUID;

@Repository
public interface ReviewQueueItemRepository extends JpaRepository<ReviewQueueItem, UUID> {

    List<ReviewQueueItem> findBySessionIdAndPositionGreaterThanEqualOrderByPositionAsc(
            UUID sessionId, int position, Pageable pageable);

    List<ReviewQueueItem> findBySessionIdOrderByPositionAsc(UUID sessionId);
}
