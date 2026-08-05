package top.kariscode.karisreview.auth.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.auth.dto.ResetPasswordRequest;
import top.kariscode.karisreview.auth.entity.PasswordResetCode;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.outbox.DomainEvent;
import top.kariscode.karisreview.common.outbox.OutboxEventTypes;
import top.kariscode.karisreview.common.outbox.OutboxPublisher;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PasswordResetServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private PasswordResetCodeService codeService;
    @Mock
    private OutboxPublisher outboxPublisher;
    @Mock
    private AuthService authService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private PasswordResetService service;

    @BeforeEach
    void setUp() {
        service = new PasswordResetService(
                userRepository, codeService, authService, outboxPublisher, objectMapper);
    }

    @Test
    void sendResetCodeIssuesAndSendsForExistingUser() {
        User user = new User();
        user.setEmail("a@b.c");
        when(userRepository.findByEmail("a@b.c")).thenReturn(Optional.of(user));
        when(codeService.issueCode("a@b.c", PasswordResetCodeService.PURPOSE_RESET))
                .thenReturn("123456");

        service.sendResetCode("a@b.c");

        verify(outboxPublisher).publish(any(DomainEvent.class));
    }

    @Test
    void sendResetCodeSilentlySucceedsForMissingEmail() {
        when(userRepository.findByEmail("missing@b.c")).thenReturn(Optional.empty());

        service.sendResetCode("missing@b.c");

        verify(codeService, never()).issueCode(any(), any());
        verify(outboxPublisher, never()).publish(any());
    }

    @Test
    void sendRegisterCodeRejectsExistingEmail() {
        when(userRepository.existsByEmail("a@b.c")).thenReturn(true);

        BusinessException exception = assertThrows(
                BusinessException.class, () -> service.sendRegisterCode("a@b.c"));

        assertEquals(400, exception.getCode());
        assertEquals("auth.email.registered", exception.getMessage());
        verify(outboxPublisher, never()).publish(any());
    }

    @Test
    void sendRegisterCodeIssuesAndSendsForNewEmail() {
        when(userRepository.existsByEmail("a@b.c")).thenReturn(false);
        when(codeService.issueCode("a@b.c", PasswordResetCodeService.PURPOSE_REGISTER))
                .thenReturn("654321");

        service.sendRegisterCode("a@b.c");

        verify(outboxPublisher).publish(any(DomainEvent.class));
    }

    @Test
    void resetPasswordConsumesCodeAndResets() {
        UUID userId = UUID.randomUUID();
        User user = new User();
        user.setId(userId);
        user.setEmail("a@b.c");
        ResetPasswordRequest request = new ResetPasswordRequest();
        request.setEmail("a@b.c");
        request.setCode("123456");
        request.setNewPassword("new-password");
        PasswordResetCode record = new PasswordResetCode();

        when(userRepository.findByEmail("a@b.c")).thenReturn(Optional.of(user));
        when(codeService.verifyCode("a@b.c", PasswordResetCodeService.PURPOSE_RESET, "123456"))
                .thenReturn(record);

        service.resetPassword(request);

        verify(codeService).consume(record);
        verify(authService).resetPassword(userId, "new-password");
    }

    @Test
    void resetPasswordRejectsMissingEmail() {
        ResetPasswordRequest request = new ResetPasswordRequest();
        request.setEmail("missing@b.c");
        request.setCode("123456");
        request.setNewPassword("new-password");
        when(userRepository.findByEmail("missing@b.c")).thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class, () -> service.resetPassword(request));

        assertEquals(400, exception.getCode());
        assertEquals("auth.password.code.invalid", exception.getMessage());
        verify(authService, never()).resetPassword(any(), any());
    }
}
