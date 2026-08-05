package top.kariscode.karisreview.auth.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.auth.entity.PasswordResetCode;
import top.kariscode.karisreview.auth.repository.PasswordResetCodeRepository;
import top.kariscode.karisreview.common.exception.BusinessException;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PasswordResetCodeServiceTest {

    @Mock
    private PasswordResetCodeRepository repository;

    private PasswordResetCodeService service;

    @BeforeEach
    void setUp() {
        service = new PasswordResetCodeService(repository);
    }

    @Test
    void issueCodeGeneratesSixDigitCodeAndSaves() {
        when(repository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
                "a@b.c", PasswordResetCodeService.PURPOSE_REGISTER))
                .thenReturn(Optional.empty());

        String code = service.issueCode("a@b.c", PasswordResetCodeService.PURPOSE_REGISTER);

        assertTrue(code.matches("\\d{6}"));
        verify(repository).save(any(PasswordResetCode.class));
    }

    @Test
    void issueCodeRejectsRepeatedRequestWithinCooldown() {
        PasswordResetCode existing = new PasswordResetCode();
        existing.setExpiresAt(LocalDateTime.now().plusMinutes(10));
        when(repository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
                "a@b.c", PasswordResetCodeService.PURPOSE_REGISTER))
                .thenReturn(Optional.of(existing));

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.issueCode("a@b.c", PasswordResetCodeService.PURPOSE_REGISTER));

        assertEquals(429, exception.getCode());
        assertEquals("auth.password.code.too.frequent", exception.getMessage());
        verify(repository, never()).save(any());
    }

    @Test
    void verifyCodeAcceptsMatchingCode() {
        PasswordResetCode record = new PasswordResetCode();
        record.setEmail("a@b.c");
        record.setCode("123456");
        record.setExpiresAt(LocalDateTime.now().plusMinutes(10));
        when(repository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
                "a@b.c", PasswordResetCodeService.PURPOSE_RESET))
                .thenReturn(Optional.of(record));

        PasswordResetCode result = service.verifyCode(
                "a@b.c", PasswordResetCodeService.PURPOSE_RESET, "123456");

        assertEquals(record, result);
    }

    @Test
    void verifyCodeRejectsWrongCodeAndIncrementsAttempts() {
        PasswordResetCode record = new PasswordResetCode();
        record.setCode("123456");
        record.setExpiresAt(LocalDateTime.now().plusMinutes(10));
        when(repository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
                "a@b.c", PasswordResetCodeService.PURPOSE_RESET))
                .thenReturn(Optional.of(record));

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.verifyCode("a@b.c", PasswordResetCodeService.PURPOSE_RESET, "000000"));

        assertEquals(400, exception.getCode());
        assertEquals("auth.password.code.invalid", exception.getMessage());
        assertEquals(1, record.getAttemptCount());
        verify(repository).save(record);
    }

    @Test
    void verifyCodeRejectsExpiredCode() {
        PasswordResetCode record = new PasswordResetCode();
        record.setCode("123456");
        record.setExpiresAt(LocalDateTime.now().minusMinutes(1));
        when(repository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
                "a@b.c", PasswordResetCodeService.PURPOSE_RESET))
                .thenReturn(Optional.of(record));

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.verifyCode("a@b.c", PasswordResetCodeService.PURPOSE_RESET, "123456"));

        assertEquals(400, exception.getCode());
        assertEquals("auth.password.code.expired", exception.getMessage());
    }

    @Test
    void verifyCodeRejectsTooManyAttempts() {
        PasswordResetCode record = new PasswordResetCode();
        record.setCode("123456");
        record.setExpiresAt(LocalDateTime.now().plusMinutes(10));
        record.setAttemptCount(10);
        when(repository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
                "a@b.c", PasswordResetCodeService.PURPOSE_RESET))
                .thenReturn(Optional.of(record));

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.verifyCode("a@b.c", PasswordResetCodeService.PURPOSE_RESET, "123456"));

        assertEquals(400, exception.getCode());
        assertEquals("auth.password.code.too.many.attempts", exception.getMessage());
    }

    @Test
    void verifyCodeRejectsMissingRecord() {
        when(repository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
                "a@b.c", PasswordResetCodeService.PURPOSE_RESET))
                .thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.verifyCode("a@b.c", PasswordResetCodeService.PURPOSE_RESET, "123456"));

        assertEquals(400, exception.getCode());
        assertEquals("auth.password.code.invalid", exception.getMessage());
    }

    @Test
    void consumeMarksRecordUsed() {
        PasswordResetCode record = new PasswordResetCode();
        service.consume(record);
        assertTrue(record.isUsed());
        verify(repository).save(record);
    }

    @Test
    void cleanupExpiredCodesDeletesCodesExpiredBeyondRetention() {
        when(repository.deleteExpiredBefore(any())).thenReturn(3);

        service.cleanupExpiredCodes();

        verify(repository).deleteExpiredBefore(any());
    }
}
