package top.kariscode.karisreview.backup.storage;

/**
 * 备份快照存储抽象（WP-1/G1）：快照数据外置到对象存储，与主数据库故障域分离。
 *
 * <p>实现：
 * <ul>
 *   <li>{@link LocalBackupStorage} — 本地磁盘（默认，适合单机部署，独立卷挂载）；</li>
 *   <li>{@link S3BackupStorage} — MinIO / S3 协议对象存储（生产推荐，异地容灾）。</li>
 * </ul>
 */
public interface BackupStorage {

    /**
     * 保存快照，返回存储元数据（键、大小、SHA-256）。
     * 同一 key 重复保存视为覆盖（幂等）。
     */
    StorageResult save(String key, byte[] content);

    /** 读取快照内容；不存在返回 null。 */
    byte[] load(String key);

    /** 删除快照；不存在时静默成功。 */
    void delete(String key);

    /** 当前存储后端类型标识（local / s3）。 */
    String type();

    /** 存储结果元数据。 */
    record StorageResult(String key, long sizeBytes, String sha256) {}
}
