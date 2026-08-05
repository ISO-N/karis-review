package top.kariscode.karisreview.backup.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.backup.entity.BackupSnapshot;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface BackupRepository extends JpaRepository<BackupSnapshot, UUID> {
    Optional<BackupSnapshot> findFirstByUserIdOrderByCreatedAtDesc(UUID userId);
    void deleteByUserId(UUID userId);

    /**
     * 保留策略：每个用户仅保留最近 {@code keep} 份快照，其余删除。
     * 返回被删除的行数。
     */
    @Modifying
    @Query(value = "DELETE FROM backup_snapshots b USING (" +
                   "SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn " +
                   "FROM backup_snapshots) ranked " +
                   "WHERE b.id = ranked.id AND ranked.rn > :keep",
           nativeQuery = true)
    int deleteExcessSnapshots(@Param("keep") int keep);
}
