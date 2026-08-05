package top.kariscode.karisreview.common.outbox;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Outbox 清理任务：已处理记录保留 7 天，死信保留 30 天。
 */
@Service
public class OutboxCleanupTask {

    private static final Logger log = LoggerFactory.getLogger(OutboxCleanupTask.class);

    private final OutboxRepository outboxRepository;

    public OutboxCleanupTask(OutboxRepository outboxRepository) {
        this.outboxRepository = outboxRepository;
    }

    @Scheduled(cron = "0 40 3 * * *")
    @Transactional
    public void cleanup() {
        LocalDateTime processedCutoff = LocalDateTime.now().minusDays(7);
        int processed = outboxRepository.deleteProcessedBefore(processedCutoff);

        LocalDateTime deadCutoff = LocalDateTime.now().minusDays(30);
        int dead = outboxRepository.deleteDeadBefore(deadCutoff);

        if (processed > 0 || dead > 0) {
            log.info("Outbox cleanup: removed {} processed, {} dead events",
                    processed, dead);
        }
    }
}
