package top.kariscode.karisreview.log.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.log.entity.UserLog;

import java.time.LocalDateTime;
import java.util.UUID;

@Repository
public interface UserLogRepository extends JpaRepository<UserLog, UUID> {

    Page<UserLog> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    Page<UserLog> findByUserIdAndLevelOrderByCreatedAtDesc(
            UUID userId, String level, Pageable pageable);

    Page<UserLog> findByUserIdAndCategoryOrderByCreatedAtDesc(
            UUID userId, String category, Pageable pageable);

    Page<UserLog> findByUserIdAndLevelAndCategoryOrderByCreatedAtDesc(
            UUID userId, String level, String category, Pageable pageable);

    void deleteByCreatedAtBefore(LocalDateTime cutoff);
}