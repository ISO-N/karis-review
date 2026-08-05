package top.kariscode.karisreview.auth.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.dto.ResetPasswordRequest;
import top.kariscode.karisreview.auth.entity.PasswordResetCode;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.outbox.DomainEvent;
import top.kariscode.karisreview.common.outbox.OutboxEventTypes;
import top.kariscode.karisreview.common.outbox.OutboxPublisher;

import java.util.Map;
import java.util.Optional;

/**
 * 找回密码编排：发送验证码邮件（异步 Outbox）→ 校验验证码 → 重置密码。
 * 邮箱不存在时也按成功返回（防枚举）。
 *
 * <p>邮件发送已异步化（WP-4）：接口不再同步依赖 SMTP，事件与验证码记录同事务提交，
 * 由 {@link MailOutboxHandler} 经 OutboxRelay 投递，失败自动重试。
 */
@Service
public class PasswordResetService {

    private final UserRepository userRepository;
    private final PasswordResetCodeService codeService;
    private final AuthService authService;
    private final OutboxPublisher outboxPublisher;
    private final ObjectMapper objectMapper;

    public PasswordResetService(UserRepository userRepository,
                                PasswordResetCodeService codeService,
                                AuthService authService,
                                OutboxPublisher outboxPublisher,
                                ObjectMapper objectMapper) {
        this.userRepository = userRepository;
        this.codeService = codeService;
        this.authService = authService;
        this.outboxPublisher = outboxPublisher;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public void sendResetCode(String email) {
        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) {
            return; // 防枚举：邮箱不存在也静默成功
        }
        String code = codeService.issueCode(userOpt.get().getEmail(), PasswordResetCodeService.PURPOSE_RESET);
        publishMailEvent(userOpt.get().getEmail(), code);
    }

    /**
     * 发送注册邮箱验证码。邮箱已注册时抛业务异常（注册场景可暴露该信息）。
     */
    @Transactional
    public void sendRegisterCode(String email) {
        if (userRepository.existsByEmail(email)) {
            throw new BusinessException(400, "auth.email.registered");
        }
        String code = codeService.issueCode(email, PasswordResetCodeService.PURPOSE_REGISTER);
        publishMailEvent(email, code);
    }

    private void publishMailEvent(String to, String code) {
        try {
            String payload = objectMapper.writeValueAsString(Map.of("to", to, "code", code));
            outboxPublisher.publish(new DomainEvent(
                    OutboxEventTypes.AGG_MAIL, null, OutboxEventTypes.MAIL_RESET_CODE, payload));
        } catch (Exception e) {
            throw new RuntimeException("Failed to enqueue mail event", e);
        }
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BusinessException(400, "auth.password.code.invalid"));

        PasswordResetCode record = codeService.verifyCode(
                request.getEmail(), PasswordResetCodeService.PURPOSE_RESET, request.getCode());
        codeService.consume(record);
        authService.resetPassword(user.getId(), request.getNewPassword());
    }
}
