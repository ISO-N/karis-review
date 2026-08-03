package top.kariscode.karisreview.backup.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;

import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BackupSchedulerTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private BackupService backupService;

    private BackupScheduler scheduler;

    @BeforeEach
    void setUp() {
        scheduler = new BackupScheduler(userRepository, backupService);
    }

    @Test
    void createsSnapshotForEveryUser() {
        User first = user();
        User second = user();
        when(userRepository.findAll()).thenReturn(List.of(first, second));

        scheduler.createDailySnapshots();

        verify(backupService).exportData(first.getId());
        verify(backupService).exportData(second.getId());
    }

    @Test
    void oneUserFailureDoesNotStopRemainingUsers() {
        User first = user();
        User second = user();
        when(userRepository.findAll()).thenReturn(List.of(first, second));
        doThrow(new RuntimeException("backup failed")).when(backupService).exportData(second.getId());

        scheduler.createDailySnapshots();

        verify(backupService).exportData(first.getId());
        verify(backupService).exportData(second.getId());
    }

    private User user() {
        User user = new User();
        user.setId(UUID.randomUUID());
        return user;
    }
}
