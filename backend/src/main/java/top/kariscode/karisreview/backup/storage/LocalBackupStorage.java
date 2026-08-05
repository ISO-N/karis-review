package top.kariscode.karisreview.backup.storage;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

/**
 * 本地磁盘快照存储：写入独立挂载目录（如 docker volume），
 * 作为未配置对象存储时的默认实现。目录需与主数据库存储卷分离，避免故障域重叠。
 */
@Component
@ConditionalOnProperty(name = "backup.storage.type", havingValue = "local", matchIfMissing = true)
public class LocalBackupStorage implements BackupStorage {

    private static final Logger log = LoggerFactory.getLogger(LocalBackupStorage.class);

    private final Path baseDir;

    public LocalBackupStorage(@Value("${backup.storage.local-dir:./backups}") String localDir) {
        this.baseDir = Path.of(localDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.baseDir);
        } catch (IOException e) {
            throw new IllegalStateException("Failed to create backup storage dir: " + this.baseDir, e);
        }
        log.info("Local backup storage initialized at {}", this.baseDir);
    }

    @Override
    public StorageResult save(String key, byte[] content) {
        try {
            Path target = resolve(key);
            Files.createDirectories(target.getParent());
            Files.write(target, content);
            return new StorageResult(key, content.length, sha256(content));
        } catch (IOException e) {
            throw new RuntimeException("Failed to write backup snapshot " + key, e);
        }
    }

    @Override
    public byte[] load(String key) {
        try {
            Path target = resolve(key);
            if (!Files.exists(target)) {
                return null;
            }
            return Files.readAllBytes(target);
        } catch (IOException e) {
            throw new RuntimeException("Failed to read backup snapshot " + key, e);
        }
    }

    @Override
    public void delete(String key) {
        try {
            Files.deleteIfExists(resolve(key));
        } catch (IOException e) {
            throw new RuntimeException("Failed to delete backup snapshot " + key, e);
        }
    }

    @Override
    public String type() {
        return "local";
    }

    /** 防止路径穿越：key 仅允许安全字符。 */
    private Path resolve(String key) {
        if (key == null || !key.matches("[A-Za-z0-9/._-]+")) {
            throw new IllegalArgumentException("Unsafe storage key: " + key);
        }
        return baseDir.resolve(key).normalize();
    }

    static String sha256(byte[] content) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(content));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
