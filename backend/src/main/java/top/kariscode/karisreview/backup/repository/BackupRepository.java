package top.kariscode.karisreview.backup.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.backup.entity.BackupSnapshot;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface BackupRepository extends JpaRepository<BackupSnapshot, UUID> {
    Optional<BackupSnapshot> findFirstByUserIdOrderByCreatedAtDesc(UUID userId);
    void deleteByUserId(UUID userId);
}