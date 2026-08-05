package top.kariscode.karisreview.backup.storage;

import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import io.minio.StatObjectArgs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.ByteArrayInputStream;
import java.io.InputStream;

/**
 * S3 协议对象存储快照存储（MinIO / 阿里云 OSS / 腾讯云 COS S3 端点）。
 * 生产环境推荐：备份数据与主库异地容灾，彻底消除故障域重叠（G1）。
 */
@Component
@ConditionalOnProperty(name = "backup.storage.type", havingValue = "s3")
public class S3BackupStorage implements BackupStorage {

    private static final Logger log = LoggerFactory.getLogger(S3BackupStorage.class);

    private final MinioClient client;
    private final String bucket;
    private final String prefix;

    public S3BackupStorage(@Value("${backup.storage.s3.endpoint}") String endpoint,
                           @Value("${backup.storage.s3.access-key}") String accessKey,
                           @Value("${backup.storage.s3.secret-key}") String secretKey,
                           @Value("${backup.storage.s3.bucket}") String bucket,
                           @Value("${backup.storage.s3.prefix:backups}") String prefix) {
        this.client = MinioClient.builder()
                .endpoint(endpoint)
                .credentials(accessKey, secretKey)
                .build();
        this.bucket = bucket;
        this.prefix = prefix;
        ensureBucket();
        log.info("S3 backup storage initialized: endpoint={}, bucket={}, prefix={}",
                endpoint, bucket, prefix);
    }

    private void ensureBucket() {
        try {
            boolean exists = client.bucketExists(BucketExistsArgs.builder().bucket(bucket).build());
            if (!exists) {
                client.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
                log.info("Created backup bucket {}", bucket);
            }
        } catch (Exception e) {
            throw new IllegalStateException("Failed to init backup bucket " + bucket, e);
        }
    }

    @Override
    public StorageResult save(String key, byte[] content) {
        try (InputStream in = new ByteArrayInputStream(content)) {
            String object = objectKey(key);
            client.putObject(PutObjectArgs.builder()
                    .bucket(bucket)
                    .object(object)
                    .stream(in, content.length, -1)
                    .build());
            return new StorageResult(key, content.length, LocalBackupStorage.sha256(content));
        } catch (Exception e) {
            throw new RuntimeException("Failed to upload backup snapshot " + key, e);
        }
    }

    @Override
    public byte[] load(String key) {
        try (InputStream in = client.getObject(GetObjectArgs.builder()
                .bucket(bucket)
                .object(objectKey(key))
                .build())) {
            return in.readAllBytes();
        } catch (Exception e) {
            if (e.getMessage() != null && e.getMessage().contains("NoSuchKey")) {
                return null;
            }
            throw new RuntimeException("Failed to read backup snapshot " + key, e);
        }
    }

    @Override
    public void delete(String key) {
        try {
            // 存在性检查：不存在则静默成功
            client.statObject(StatObjectArgs.builder().bucket(bucket).object(objectKey(key)).build());
            client.removeObject(RemoveObjectArgs.builder().bucket(bucket).object(objectKey(key)).build());
        } catch (Exception ignored) {
            // 不存在或删除失败均不阻断（下一次清理重试）
        }
    }

    @Override
    public String type() {
        return "s3";
    }

    private String objectKey(String key) {
        return prefix + "/" + key;
    }
}
