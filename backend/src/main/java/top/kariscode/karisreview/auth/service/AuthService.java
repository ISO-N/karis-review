package top.kariscode.karisreview.auth.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.dto.LoginRequest;
import top.kariscode.karisreview.auth.dto.LoginResponse;
import top.kariscode.karisreview.auth.dto.RegisterRequest;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.config.JwtProvider;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtProvider jwtProvider) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtProvider = jwtProvider;
    }

    @Transactional
    public LoginResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BusinessException(400, "邮箱已被注册");
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));

        user = userRepository.save(user);

        String token = jwtProvider.generateToken(user.getId(), user.getEmail());
        return new LoginResponse(token, user.getId(), user.getEmail());
    }

    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BusinessException(401, "邮箱或密码错误"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BusinessException(401, "邮箱或密码错误");
        }

        String token = jwtProvider.generateToken(user.getId(), user.getEmail());
        return new LoginResponse(token, user.getId(), user.getEmail());
    }

    public void logout() {
        // Client-side token discard; server-side blacklist is optional
    }
}