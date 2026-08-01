package top.kariscode.karisreview.backup.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;

import java.util.List;

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

    private final UserRepository userRepository;
    private final BackupService backupService;

    public BackupScheduler(UserRepository userRepository, BackupService backupService) {
        this.userRepository = userRepository;
        this.backupService = backupService;
    }

    @Scheduled(cron = "0 10 4 * * *")
    public void createDailySnapshots() {
        List<User> users = userRepository.findAll();
        int succeeded = 0;
        for (User user : users) {
            try {
                backupService.exportData(user.getId());
                succeeded++;
            } catch (Exception e) {
                log.error("Scheduled backup failed for user {}", user.getId(), e);
            }
        }
        log.info("Scheduled backup complete: {} users backed up, {} total", succeeded, users.size());
    }
}