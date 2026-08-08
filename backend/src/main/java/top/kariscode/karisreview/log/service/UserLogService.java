package top.kariscode.karisreview.log.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.common.exception.ServerErrorReporter;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.common.util.PagingHelper;
import top.kariscode.karisreview.log.dto.UserLogResponse;
import top.kariscode.karisreview.log.entity.UserLog;
import top.kariscode.karisreview.log.repository.UserLogRepository;
import top.kariscode.karisreview.log.util.LogDesensitizer;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class UserLogService implements ServerErrorReporter {

    private static final Logger log = LoggerFactory.getLogger(UserLogService.class);
    private static final int LOG_RETENTION_DAYS = 30;

    private final UserLogRepository userLogRepository;
    private final ObjectMapper objectMapper;

    public UserLogService(UserLogRepository userLogRepository, ObjectMapper objectMapper) {
        this.userLogRepository = userLogRepository;
        this.objectMapper = objectMapper;
    }

    /**
     * Write a desensitized log entry for the given user.
     */
    @Transactional
    public void log(UUID userId, String level, String category, String message) {
        log(userId, level, category, message, null);
    }

    /**
     * ServerErrorReporter 实现（架构评审 B1）：GlobalExceptionHandler 经 common 接口
     * 上报 500 错误，依赖方向 common ← log，切断编译期环。
     */
    @Override
    @Transactional
    public void report(UUID userId, String messageKey, Map<String, Object> detail) {
        log(userId, "ERROR", "SYSTEM", messageKey, detail);
    }

    /**
     * Write a desensitized log entry with structured details.
     */
    @Transactional
    public void log(UUID userId, String level, String category, String message,
                    Map<String, Object> details) {
        UserLog entity = new UserLog();
        entity.setUserId(userId);
        entity.setLevel(level != null ? level : "INFO");
        entity.setCategory(category != null ? category : "SYSTEM");
        entity.setMessage(LogDesensitizer.desensitize(message));
        if (details != null && !details.isEmpty()) {
            try {
                entity.setDetails(objectMapper.writeValueAsString(details));
            } catch (JsonProcessingException e) {
                log.warn("Failed to serialize log details for user {}", userId, e);
            }
        }
        userLogRepository.save(entity);
    }

    /**
     * Query paginated logs for a user, optionally filtered by level and/or category.
     */
    public Page<UserLogResponse> getLogs(UUID userId, String level, String category,
                                          int page, int size) {
        // 分页 clamp 统一走 PagingHelper（架构评审 B4）。
        Pageable pageable = PageRequest.of(
                PagingHelper.safePage(page), PagingHelper.safeSize(size));

        Page<UserLog> logPage;
        if (level != null && !level.isBlank() && category != null && !category.isBlank()) {
            logPage = userLogRepository.findByUserIdAndLevelAndCategoryOrderByCreatedAtDesc(
                    userId, level.trim().toUpperCase(), category.trim().toUpperCase(), pageable);
        } else if (level != null && !level.isBlank()) {
            logPage = userLogRepository.findByUserIdAndLevelOrderByCreatedAtDesc(
                    userId, level.trim().toUpperCase(), pageable);
        } else if (category != null && !category.isBlank()) {
            logPage = userLogRepository.findByUserIdAndCategoryOrderByCreatedAtDesc(
                    userId, category.trim().toUpperCase(), pageable);
        } else {
            logPage = userLogRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        }

        return logPage.map(this::toResponse);
    }

    /**
     * Daily cleanup of logs older than 30 days.
     * Runs at 03:00 every day.
     */
    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void cleanupOldLogs() {
        LocalDateTime cutoff = DateUtils.now().minusDays(LOG_RETENTION_DAYS);
        userLogRepository.deleteByCreatedAtBefore(cutoff);
        log.info("Cleaned up user_logs older than {}", cutoff);
    }

    private UserLogResponse toResponse(UserLog entity) {
        Object detailsObj = null;
        if (entity.getDetails() != null) {
            try {
                detailsObj = objectMapper.readValue(entity.getDetails(), Map.class);
            } catch (JsonProcessingException e) {
                detailsObj = entity.getDetails();
            }
        }
        return new UserLogResponse(
                entity.getId(),
                entity.getLevel(),
                entity.getCategory(),
                entity.getMessage(),
                detailsObj,
                entity.getCreatedAt()
        );
    }
}