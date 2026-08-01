package top.kariscode.karisreview.settings.controller;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.settings.dto.UpdateSettingsRequest;
import top.kariscode.karisreview.settings.dto.UserSettingsResponse;
import top.kariscode.karisreview.settings.service.SettingsService;

import java.util.UUID;

@RestController
@RequestMapping("/api/settings")
public class SettingsController {

    private final SettingsService settingsService;

    public SettingsController(SettingsService settingsService) {
        this.settingsService = settingsService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<UserSettingsResponse>> getSettings(
            @AuthenticationPrincipal UUID userId) {
        UserSettingsResponse settings = settingsService.getSettings(userId);
        return ResponseEntity.ok(ApiResponse.success(settings));
    }

    @PutMapping
    public ResponseEntity<ApiResponse<UserSettingsResponse>> updateSettings(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody UpdateSettingsRequest request) {
        UserSettingsResponse settings = settingsService.updateSettings(userId, request);
        return ResponseEntity.ok(ApiResponse.success("设置已更新", settings));
    }
}