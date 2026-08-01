package top.kariscode.karisreview.auth.controller;

import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import top.kariscode.karisreview.auth.dto.LoginRequest;
import top.kariscode.karisreview.auth.dto.LoginResponse;
import top.kariscode.karisreview.auth.dto.RegisterRequest;
import top.kariscode.karisreview.auth.service.AuthService;
import top.kariscode.karisreview.common.dto.ApiResponse;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<LoginResponse>> register(@Valid @RequestBody RegisterRequest request) {
        LoginResponse response = authService.register(request);
        return ResponseEntity.ok(ApiResponse.success("注册成功", response));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success("登录成功", response));
    }

    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout() {
        authService.logout();
        return ResponseEntity.ok(ApiResponse.success("已登出", null));
    }
}