package top.kariscode.karisreview.log.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import top.kariscode.karisreview.log.dto.UserLogResponse;
import top.kariscode.karisreview.log.entity.UserLog;
import top.kariscode.karisreview.log.repository.UserLogRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserLogServiceTest {

    @Mock
    private UserLogRepository userLogRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private UserLogService service;

    @BeforeEach
    void setUp() {
        service = new UserLogService(userLogRepository, objectMapper);
    }

    @Test
    void logUsesDefaultsAndDesensitizesMessage() throws Exception {
        UUID userId = UUID.randomUUID();

        service.log(userId, null, null, "user@example.com failed");

        ArgumentCaptor<UserLog> captor = ArgumentCaptor.forClass(UserLog.class);
        verify(userLogRepository).save(captor.capture());
        UserLog entity = captor.getValue();
        assertEquals(userId, entity.getUserId());
        assertEquals("INFO", entity.getLevel());
        assertEquals("SYSTEM", entity.getCategory());
        assertFalse(entity.getMessage().contains("user@example.com"));
        assertTrue(entity.getMessage().contains("[EMAIL]"));
    }

    @Test
    void logSerializesStructuredDetails() throws Exception {
        UUID userId = UUID.randomUUID();
        Map<String, Object> details = Map.of("card_id", "card-1", "retry", 2);

        service.log(userId, "WARN", "SYNC", "sync failed", details);

        ArgumentCaptor<UserLog> captor = ArgumentCaptor.forClass(UserLog.class);
        verify(userLogRepository).save(captor.capture());
        assertNotNull(captor.getValue().getDetails());
        assertTrue(captor.getValue().getDetails().contains("\"card_id\""));
    }

    @Test
    void getLogsClampsPageAndSize() {
        UUID userId = UUID.randomUUID();
        UserLog log = log("INFO", "AUTH");
        when(userLogRepository.findByUserIdOrderByCreatedAtDesc(eq(userId), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(log)));

        Page<UserLogResponse> page = service.getLogs(userId, null, null, -2, 1000);

        assertEquals(1, page.getTotalElements());
        ArgumentCaptor<Pageable> pageableCaptor = ArgumentCaptor.forClass(Pageable.class);
        verify(userLogRepository).findByUserIdOrderByCreatedAtDesc(eq(userId), pageableCaptor.capture());
        Pageable pageable = pageableCaptor.getValue();
        assertEquals(0, pageable.getPageNumber());
        assertEquals(100, pageable.getPageSize());
    }

    @Test
    void getLogsFiltersByLevelAndCategory() {
        UUID userId = UUID.randomUUID();
        when(userLogRepository.findByUserIdAndLevelAndCategoryOrderByCreatedAtDesc(
                eq(userId), eq("INFO"), eq("REVIEW"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        service.getLogs(userId, " info ", " review ", 0, 50);

        verify(userLogRepository).findByUserIdAndLevelAndCategoryOrderByCreatedAtDesc(
                eq(userId), eq("INFO"), eq("REVIEW"), any(Pageable.class));
    }

    @Test
    void getLogsFiltersByLevelOnly() {
        UUID userId = UUID.randomUUID();
        when(userLogRepository.findByUserIdAndLevelOrderByCreatedAtDesc(
                eq(userId), eq("ERROR"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        service.getLogs(userId, " error ", null, 0, 50);

        verify(userLogRepository).findByUserIdAndLevelOrderByCreatedAtDesc(
                eq(userId), eq("ERROR"), any(Pageable.class));
    }

    @Test
    void getLogsFiltersByCategoryOnly() {
        UUID userId = UUID.randomUUID();
        when(userLogRepository.findByUserIdAndCategoryOrderByCreatedAtDesc(
                eq(userId), eq("BACKUP"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        service.getLogs(userId, null, " backup ", 0, 50);

        verify(userLogRepository).findByUserIdAndCategoryOrderByCreatedAtDesc(
                eq(userId), eq("BACKUP"), any(Pageable.class));
    }

    @Test
    void cleanupDeletesLogsBeforeRetentionCutoff() {
        ArgumentCaptor<LocalDateTime> cutoffCaptor = ArgumentCaptor.forClass(LocalDateTime.class);

        service.cleanupOldLogs();

        verify(userLogRepository).deleteByCreatedAtBefore(cutoffCaptor.capture());
        assertTrue(cutoffCaptor.getValue().isBefore(LocalDateTime.now()));
    }

    private UserLog log(String level, String category) {
        UserLog log = new UserLog();
        log.setId(UUID.randomUUID());
        log.setLevel(level);
        log.setCategory(category);
        log.setMessage("message");
        return log;
    }
}
