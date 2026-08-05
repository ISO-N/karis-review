package top.kariscode.karisreview.auth.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.dto.ResetPasswordRequest;
import top.kariscode.karisreview.auth.entity.PasswordResetCode;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.common.exception.BusinessException;

import java.util.Optional;

/**
 * 找回密码编排：发送验证码邮件 → 校验验证码 → 重置密码。
 * 邮箱不存在时也按成功返回（防枚举）。
 */
@Service
public class PasswordResetService {

    private final UserRepository userRepository;
    private final PasswordResetCodeService codeService;
    private final MailSender mailSender;
    private final AuthService authService;

    public PasswordResetService(UserRepository userRepository,
                                PasswordResetCodeService codeService,
                                MailSender mailSender,
                                AuthService authService) {
        this.userRepository = userRepository;
        this.codeService = codeService;
        this.mailSender = mailSender;
        this.authService = authService;
    }

    @Transactional
    public void sendResetCode(String email) {
        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) {
            return; // 防枚举：邮箱不存在也静默成功
        }
        String code = codeService.issueCode(userOpt.get().getEmail(), PasswordResetCodeService.PURPOSE_RESET);
        mailSender.sendResetCode(userOpt.get().getEmail(), code);
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
        mailSender.sendResetCode(email, code);
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
