package top.kariscode.karisreview.auth.controller;

import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import top.kariscode.karisreview.auth.dto.AuthConfigResponse;
import top.kariscode.karisreview.auth.dto.ChangePasswordRequest;
import top.kariscode.karisreview.auth.dto.LoginRequest;
import top.kariscode.karisreview.auth.dto.LoginResponse;
import top.kariscode.karisreview.auth.dto.RegisterRequest;
import top.kariscode.karisreview.auth.dto.ResetPasswordRequest;
import top.kariscode.karisreview.auth.dto.SendRegisterCodeRequest;
import top.kariscode.karisreview.auth.dto.SendResetCodeRequest;
import top.kariscode.karisreview.auth.service.AuthService;
import top.kariscode.karisreview.auth.service.PasswordResetService;
import top.kariscode.karisreview.common.dto.ApiResponse;

import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final PasswordResetService passwordResetService;

    public AuthController(AuthService authService, PasswordResetService passwordResetService) {
        this.authService = authService;
        this.passwordResetService = passwordResetService;
    }

    @GetMapping("/config")
    public ResponseEntity<ApiResponse<AuthConfigResponse>> getConfig() {
        return ResponseEntity.ok(ApiResponse.success(authService.getAuthConfig()));
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<LoginResponse>> register(@Valid @RequestBody RegisterRequest request) {
        LoginResponse response = authService.register(request);
        return ResponseEntity.ok(ApiResponse.success("auth.register.success", response));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success("auth.login.success", response));
    }

    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout() {
        authService.logout();
        return ResponseEntity.ok(ApiResponse.success("auth.logout.success", null));
    }

    @SecurityRequirement(name = "bearerAuth")
    @PutMapping("/password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody ChangePasswordRequest request) {
        authService.changePassword(userId, request);
        return ResponseEntity.ok(ApiResponse.success("auth.password.changed", null));
    }

    @PostMapping("/password/reset-code")
    public ResponseEntity<ApiResponse<Void>> sendResetCode(
            @Valid @RequestBody SendResetCodeRequest request) {
        passwordResetService.sendResetCode(request.getEmail());
        return ResponseEntity.ok(ApiResponse.success("auth.password.code.sent", null));
    }

    @PostMapping("/register-code")
    public ResponseEntity<ApiResponse<Void>> sendRegisterCode(
            @Valid @RequestBody SendRegisterCodeRequest request) {
        passwordResetService.sendRegisterCode(request.getEmail());
        return ResponseEntity.ok(ApiResponse.success("auth.password.code.sent", null));
    }

    @PostMapping("/password/reset")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request) {
        passwordResetService.resetPassword(request);
        return ResponseEntity.ok(ApiResponse.success("auth.password.reset", null));
    }
}
