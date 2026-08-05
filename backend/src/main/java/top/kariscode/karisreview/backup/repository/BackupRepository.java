package top.kariscode.karisreview.backup.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.backup.entity.BackupSnapshot;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BackupRepository extends JpaRepository<BackupSnapshot, UUID> {
    Optional<BackupSnapshot> findFirstByUserIdOrderByCreatedAtDesc(UUID userId);
    void deleteByUserId(UUID userId);

    /**
     * 返回每个用户超出保留份数 {@code keep} 的快照（含 storage_key，供清理对象存储文件）。
     */
    @Query(value = "SELECT * FROM backup_snapshots b WHERE b.id IN (" +
                   "SELECT id FROM (SELECT id, ROW_NUMBER() OVER " +
                   "(PARTITION BY user_id ORDER BY created_at DESC) AS rn " +
                   "FROM backup_snapshots) ranked WHERE ranked.rn > :keep)",
           nativeQuery = true)
    List<BackupSnapshot> findExcessSnapshots(@Param("keep") int keep);
}
