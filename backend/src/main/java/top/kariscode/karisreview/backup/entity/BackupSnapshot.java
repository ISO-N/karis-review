package top.kariscode.karisreview.backup.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "backup_snapshots")
public class BackupSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /** 快照数据（本地模式仍存库内；对象存储模式下为 NULL，数据在对象存储）。 */
    @Column
    @JdbcTypeCode(SqlTypes.JSON)
    private String data;

    /** 对象存储键（storage_status = OBJECT_STORAGE 时有效）。 */
    @Column(name = "storage_key")
    private String storageKey;

    @Column(name = "storage_size")
    private Long storageSize;

    @Column(name = "storage_sha256")
    private String storageSha256;

    @Column(name = "storage_status", nullable = false, length = 16)
    private String storageStatus = "LOCAL";

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getData() { return data; }
    public void setData(String data) { this.data = data; }
    public String getStorageKey() { return storageKey; }
    public void setStorageKey(String storageKey) { this.storageKey = storageKey; }
    public Long getStorageSize() { return storageSize; }
    public void setStorageSize(Long storageSize) { this.storageSize = storageSize; }
    public String getStorageSha256() { return storageSha256; }
    public void setStorageSha256(String storageSha256) { this.storageSha256 = storageSha256; }
    public String getStorageStatus() { return storageStatus; }
    public void setStorageStatus(String storageStatus) { this.storageStatus = storageStatus; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}