package top.kariscode.karisreview.backup.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.auth.api.IdentityPort;

import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BackupSchedulerTest {

    @Mock
    private IdentityPort identityPort;

    @Mock
    private BackupService backupService;

    private BackupScheduler scheduler;

    @BeforeEach
    void setUp() {
        scheduler = new BackupScheduler(identityPort, backupService);
    }

    @Test
    void createsSnapshotForEveryUser() {
        UUID first = UUID.randomUUID();
        UUID second = UUID.randomUUID();
        when(identityPort.findAllUserIds()).thenReturn(List.of(first, second));

        scheduler.createDailySnapshots();

        verify(backupService).exportData(first);
        verify(backupService).exportData(second);
    }

    @Test
    void oneUserFailureDoesNotStopRemainingUsers() {
        UUID first = UUID.randomUUID();
        UUID second = UUID.randomUUID();
        when(identityPort.findAllUserIds()).thenReturn(List.of(first, second));
        doThrow(new RuntimeException("backup failed")).when(backupService).exportData(second);

        scheduler.createDailySnapshots();

        verify(backupService).exportData(first);
        verify(backupService).exportData(second);
    }
}
