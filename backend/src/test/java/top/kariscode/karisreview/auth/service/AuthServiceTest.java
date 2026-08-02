package top.kariscode.karisreview.auth.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import top.kariscode.karisreview.auth.dto.LoginRequest;
import top.kariscode.karisreview.auth.dto.LoginResponse;
import top.kariscode.karisreview.auth.dto.RegisterRequest;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.config.JwtProvider;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtProvider jwtProvider;

    private AuthService service;

    @BeforeEach
    void setUp() {
        service = new AuthService(userRepository, passwordEncoder, jwtProvider);
    }

    @Test
    void registerHashesPasswordAndReturnsToken() {
        UUID userId = UUID.randomUUID();
        RegisterRequest request = request("new@example.com", "password123");
        when(userRepository.existsByEmail(request.getEmail())).thenReturn(false);
        when(passwordEncoder.encode(request.getPassword())).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(userId);
            return user;
        });
        when(jwtProvider.generateToken(userId, request.getEmail())).thenReturn("token");

        LoginResponse response = service.register(request);

        assertEquals("token", response.getToken());
        assertEquals(userId, response.getUser().getId());
        assertEquals(request.getEmail(), response.getUser().getEmail());
        verify(userRepository).save(any(User.class));
    }

    @Test
    void registerRejectsDuplicateEmail() {
        RegisterRequest request = request("taken@example.com", "password123");
        when(userRepository.existsByEmail(request.getEmail())).thenReturn(true);

        BusinessException exception = assertThrows(
                BusinessException.class, () -> service.register(request));

        assertEquals(400, exception.getCode());
        assertEquals("邮箱已被注册", exception.getMessage());
        verify(userRepository, never()).save(any());
    }

    @Test
    void loginReturnsTokenForValidCredentials() {
        UUID userId = UUID.randomUUID();
        User user = new User();
        user.setId(userId);
        user.setEmail("user@example.com");
        user.setPasswordHash("hashed");
        LoginRequest request = new LoginRequest();
        request.setEmail(user.getEmail());
        request.setPassword("password123");

        when(userRepository.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
        when(passwordEncoder.matches(request.getPassword(), user.getPasswordHash()))
                .thenReturn(true);
        when(jwtProvider.generateToken(userId, user.getEmail())).thenReturn("token");

        LoginResponse response = service.login(request);

        assertEquals("token", response.getToken());
        assertEquals(userId, response.getUser().getId());
    }

    @Test
    void loginRejectsWrongPassword() {
        User user = new User();
        user.setEmail("user@example.com");
        user.setPasswordHash("hashed");
        LoginRequest request = new LoginRequest();
        request.setEmail(user.getEmail());
        request.setPassword("wrong");

        when(userRepository.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
        when(passwordEncoder.matches(request.getPassword(), user.getPasswordHash()))
                .thenReturn(false);

        BusinessException exception = assertThrows(
                BusinessException.class, () -> service.login(request));

        assertEquals(401, exception.getCode());
        assertEquals("邮箱或密码错误", exception.getMessage());
    }

    @Test
    void loginRejectsMissingUser() {
        LoginRequest request = new LoginRequest();
        request.setEmail("missing@example.com");
        request.setPassword("password123");
        when(userRepository.findByEmail(request.getEmail())).thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class, () -> service.login(request));

        assertEquals(401, exception.getCode());
        assertEquals("邮箱或密码错误", exception.getMessage());
    }

    @Test
    void logoutIsClientSideNoOp() {
        service.logout();
        assertNotNull(service);
    }

    private RegisterRequest request(String email, String password) {
        RegisterRequest request = new RegisterRequest();
        request.setEmail(email);
        request.setPassword(password);
        return request;
    }
}
