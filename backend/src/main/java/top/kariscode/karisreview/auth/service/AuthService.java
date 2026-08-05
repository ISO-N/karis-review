package top.kariscode.karisreview.auth.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.dto.AuthConfigResponse;
import top.kariscode.karisreview.auth.dto.ChangePasswordRequest;
import top.kariscode.karisreview.auth.dto.LoginRequest;
import top.kariscode.karisreview.auth.dto.LoginResponse;
import top.kariscode.karisreview.auth.dto.RegisterRequest;
import top.kariscode.karisreview.auth.entity.PasswordResetCode;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.outbox.DomainEvent;
import top.kariscode.karisreview.common.outbox.OutboxEventTypes;
import top.kariscode.karisreview.common.outbox.OutboxPublisher;
import top.kariscode.karisreview.config.InviteCodeConfig;
import top.kariscode.karisreview.config.JwtProvider;
import top.kariscode.karisreview.log.service.UserLogService;

import java.util.Map;
import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;
    private final InviteCodeConfig inviteCodeConfig;
    private final UserLogService userLogService;
    private final PasswordResetCodeService codeService;
    private final OutboxPublisher outboxPublisher;
    private final ObjectMapper objectMapper;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtProvider jwtProvider,
                       InviteCodeConfig inviteCodeConfig,
                       UserLogService userLogService,
                       PasswordResetCodeService codeService,
                       OutboxPublisher outboxPublisher,
                       ObjectMapper objectMapper) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtProvider = jwtProvider;
        this.inviteCodeConfig = inviteCodeConfig;
        this.userLogService = userLogService;
        this.codeService = codeService;
        this.outboxPublisher = outboxPublisher;
        this.objectMapper = objectMapper;
    }

    public AuthConfigResponse getAuthConfig() {
        return new AuthConfigResponse(inviteCodeConfig.isEnabled());
    }

    @Transactional
    public LoginResponse register(RegisterRequest request) {
        if (inviteCodeConfig.isEnabled()) {
            String inviteCode = request.getInviteCode() == null
                    ? "" : request.getInviteCode().trim();
            if (inviteCode.isEmpty()) {
                throw new BusinessException(400, "auth.invite.required");
            }
            if (!inviteCodeConfig.matches(inviteCode)) {
                throw new BusinessException(400, "auth.invite.invalid");
            }
        }

        // 邮箱验证码校验（注册必须先发码并校验）
        if (request.getVerificationCode() == null || request.getVerificationCode().isBlank()) {
            throw new BusinessException(400, "auth.register.code.required");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BusinessException(400, "auth.email.registered");
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));

        user = userRepository.save(user);

        PasswordResetCode record = codeService.verifyCode(
                request.getEmail(), PasswordResetCodeService.PURPOSE_REGISTER, request.getVerificationCode());
        codeService.consume(record);

        String token = jwtProvider.generateToken(user.getId(), user.getEmail());
        userLogService.log(user.getId(), "INFO", "AUTH", "Registration successful");
        // 发布用户注册事件（阶段二 Identity 拆分：下游上下文/外部服务订阅）
        publishUserRegistered(user.getId(), user.getEmail());
        return new LoginResponse(token, user.getId(), user.getEmail());
    }

    private void publishUserRegistered(UUID userId, String email) {
        try {
            String payload = objectMapper.writeValueAsString(Map.of("userId", userId.toString(), "email", email));
            outboxPublisher.publish(new DomainEvent(
                    OutboxEventTypes.AGG_USER, userId.toString(), OutboxEventTypes.USER_REGISTERED, payload));
        } catch (Exception e) {
            userLogService.log(userId, "WARN", "AUTH",
                    "Failed to publish user registered event: " + e.getMessage());
        }
    }

    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BusinessException(401, "auth.email.password.wrong"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BusinessException(401, "auth.email.password.wrong");
        }

        String token = jwtProvider.generateToken(user.getId(), user.getEmail());
        userLogService.log(user.getId(), "INFO", "AUTH", "Login successful");
        return new LoginResponse(token, user.getId(), user.getEmail());
    }

    public void logout() {
        // Client-side token discard; server-side blacklist is optional
    }

    @Transactional
    public void changePassword(UUID userId, ChangePasswordRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "settings.notfound"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new BusinessException(400, "auth.password.current.wrong");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
        userLogService.log(user.getId(), "INFO", "AUTH", "Password changed");
    }

    @Transactional
    public void resetPassword(UUID userId, String newPassword) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "settings.notfound"));

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        userLogService.log(user.getId(), "INFO", "AUTH", "Password reset");
    }
}