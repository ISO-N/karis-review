package top.kariscode.karisreview.auth.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.entity.PasswordResetCode;
import top.kariscode.karisreview.auth.repository.PasswordResetCodeRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;

import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;

/**
 * 邮箱验证码的生成、校验与消费（纯逻辑，便于单测）。
 * 用途：REGISTER（注册邮箱验证）、RESET（找回密码）。
 */
@Service
public class PasswordResetCodeService {

    private static final Logger log = LoggerFactory.getLogger(PasswordResetCodeService.class);

    public static final String PURPOSE_REGISTER = "REGISTER";
    public static final String PURPOSE_RESET = "RESET";

    private static final int CODE_LENGTH = 6;
    private static final Duration CODE_TTL = Duration.ofMinutes(15);
    private static final Duration RESEND_COOLDOWN = Duration.ofSeconds(60);
    private static final int MAX_ATTEMPTS = 10;
    /** 验证码过期后的保留宽限期：超过该时间才允许被清理，便于审计排查。 */
    private static final Duration EXPIRED_RETENTION = Duration.ofDays(7);

    private final PasswordResetCodeRepository repository;
    private final SecureRandom random = new SecureRandom();

    public PasswordResetCodeService(PasswordResetCodeRepository repository) {
        this.repository = repository;
    }

    /**
     * 生成验证码。60 秒内重复请求（同邮箱同用途）抛业务异常。
     */
    @Transactional
    public String issueCode(String email, String purpose) {
        repository.deleteExpired(DateUtils.now());

        repository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(email, purpose)
                .ifPresent(existing -> {
                    if (existing.getExpiresAt().isAfter(DateUtils.now())) {
                        throw new BusinessException(429, "auth.password.code.too.frequent");
                    }
                });

        PasswordResetCode entity = new PasswordResetCode();
        entity.setEmail(email);
        entity.setPurpose(purpose);
        entity.setCode(generateCode());
        entity.setExpiresAt(DateUtils.now().plus(CODE_TTL));
        repository.save(entity);
        return entity.getCode();
    }

    /**
     * 校验验证码：不存在/错误/过期/超限均抛对应业务异常。校验通过返回有效记录。
     */
    @Transactional
    public PasswordResetCode verifyCode(String email, String purpose, String code) {
        PasswordResetCode record = repository
                .findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(email, purpose)
                .orElseThrow(() -> new BusinessException(400, "auth.password.code.invalid"));

        if (record.getExpiresAt().isBefore(DateUtils.now())) {
            throw new BusinessException(400, "auth.password.code.expired");
        }
        if (record.getAttemptCount() >= MAX_ATTEMPTS) {
            throw new BusinessException(400, "auth.password.code.too.many.attempts");
        }

        if (!constantTimeEquals(record.getCode(), code)) {
            record.setAttemptCount(record.getAttemptCount() + 1);
            repository.save(record);
            throw new BusinessException(400, "auth.password.code.invalid");
        }
        return record;
    }

    /**
     * 消费验证码（标记 used），防止重复使用。
     */
    @Transactional
    public void consume(PasswordResetCode record) {
        record.setUsed(true);
        repository.save(record);
    }

    /**
     * 定期清理：删除已过期超过 7 天的验证码（每天 03:40，与 user_logs 的 03:00 错开）。
     */
    @Scheduled(cron = "0 40 3 * * *")
    @Transactional
    public void cleanupExpiredCodes() {
        LocalDateTime cutoff = DateUtils.now().minus(EXPIRED_RETENTION);
        int deleted = repository.deleteExpiredBefore(cutoff);
        if (deleted > 0) {
            log.info("Cleaned up {} expired email verification codes older than {}", deleted, cutoff);
        }
    }

    private String generateCode() {
        StringBuilder sb = new StringBuilder(CODE_LENGTH);
        for (int i = 0; i < CODE_LENGTH; i++) {
            sb.append((char) ('0' + random.nextInt(10)));
        }
        return sb.toString();
    }

    private boolean constantTimeEquals(String a, String b) {
        return MessageDigest.isEqual(a.getBytes(java.nio.charset.StandardCharsets.UTF_8),
                b.getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }
}
