package top.kariscode.karisreview.backup.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import top.kariscode.karisreview.auth.api.IdentityPort;

import java.util.List;
import java.util.UUID;

/**
 * Creates application-level backup snapshots for every user on a daily basis.
 *
 * This complements the database-level PostgreSQL backups and ensures each
 * user has a recoverable JSON snapshot inside backup_snapshots even if the
 * database volume is lost.
 */
@Component
public class BackupScheduler {

    private static final Logger log = LoggerFactory.getLogger(BackupScheduler.class);

    private final IdentityPort identityPort;
    private final BackupService backupService;

    public BackupScheduler(IdentityPort identityPort, BackupService backupService) {
        this.identityPort = identityPort;
        this.backupService = backupService;
    }

    @Scheduled(cron = "0 10 4 * * *")
    public void createDailySnapshots() {
        List<UUID> userIds = identityPort.findAllUserIds();
        int succeeded = 0;
        for (UUID userId : userIds) {
            try {
                backupService.exportData(userId);
                succeeded++;
            } catch (Exception e) {
                log.error("Scheduled backup failed for user {}", userId, e);
            }
        }
        log.info("Scheduled backup complete: {} users backed up, {} total", succeeded, userIds.size());
    }
}