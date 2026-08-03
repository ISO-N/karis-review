package top.kariscode.karisreview.auth.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.dto.AuthConfigResponse;
import top.kariscode.karisreview.auth.dto.LoginRequest;
import top.kariscode.karisreview.auth.dto.LoginResponse;
import top.kariscode.karisreview.auth.dto.RegisterRequest;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.config.InviteCodeConfig;
import top.kariscode.karisreview.config.JwtProvider;
import top.kariscode.karisreview.log.service.UserLogService;

import java.util.Map;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;
    private final InviteCodeConfig inviteCodeConfig;
    private final UserLogService userLogService;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtProvider jwtProvider,
                       InviteCodeConfig inviteCodeConfig,
                       UserLogService userLogService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtProvider = jwtProvider;
        this.inviteCodeConfig = inviteCodeConfig;
        this.userLogService = userLogService;
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

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BusinessException(400, "auth.email.registered");
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));

        user = userRepository.save(user);

        String token = jwtProvider.generateToken(user.getId(), user.getEmail());
        userLogService.log(user.getId(), "INFO", "AUTH", "Registration successful");
        return new LoginResponse(token, user.getId(), user.getEmail());
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
}