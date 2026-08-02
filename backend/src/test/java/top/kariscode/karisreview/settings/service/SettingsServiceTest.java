package top.kariscode.karisreview.settings.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.settings.dto.UpdateSettingsRequest;
import top.kariscode.karisreview.settings.dto.UserSettingsResponse;

import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SettingsServiceTest {

    @Mock
    private UserRepository userRepository;

    private SettingsService service;

    @BeforeEach
    void setUp() {
        service = new SettingsService(userRepository);
    }

    @Test
    void getSettingsReturnsEmailAndRefreshTime() {
        UUID userId = UUID.randomUUID();
        User user = new User();
        user.setId(userId);
        user.setEmail("user@example.com");
        user.setRefreshTime(LocalTime.of(4, 0));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        UserSettingsResponse response = service.getSettings(userId);

        assertEquals("user@example.com", response.getEmail());
        assertEquals("04:00:00", response.getRefreshTime());
    }

    @Test
    void updateSettingsPersistsNewRefreshTime() {
        UUID userId = UUID.randomUUID();
        User user = new User();
        user.setId(userId);
        user.setEmail("user@example.com");
        user.setRefreshTime(LocalTime.of(4, 0));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(userRepository.save(user)).thenReturn(user);
        UpdateSettingsRequest request = new UpdateSettingsRequest();
        request.setRefreshTime("03:00:00");

        UserSettingsResponse response = service.updateSettings(userId, request);

        assertEquals("03:00:00", response.getRefreshTime());
        assertEquals(LocalTime.of(3, 0), user.getRefreshTime());
        verify(userRepository).save(user);
    }

    @Test
    void getSettingsRejectsMissingUser() {
        UUID userId = UUID.randomUUID();
        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.getSettings(userId));

        assertEquals(404, exception.getCode());
        assertEquals("用户不存在", exception.getMessage());
    }

    @Test
    void updateSettingsRejectsMissingUser() {
        UUID userId = UUID.randomUUID();
        when(userRepository.findById(userId)).thenReturn(Optional.empty());
        UpdateSettingsRequest request = new UpdateSettingsRequest();
        request.setRefreshTime("03:00:00");

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.updateSettings(userId, request));

        assertEquals(404, exception.getCode());
    }
}
