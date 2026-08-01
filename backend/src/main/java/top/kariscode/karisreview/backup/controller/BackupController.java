package top.kariscode.karisreview.backup.controller;

import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import top.kariscode.karisreview.backup.service.BackupService;
import top.kariscode.karisreview.common.dto.ApiResponse;

import java.util.Map;
import java.util.UUID;

@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/backup")
public class BackupController {

    private final BackupService backupService;

    public BackupController(BackupService backupService) {
        this.backupService = backupService;
    }

    @PostMapping("/export")
    public ResponseEntity<ApiResponse<Map<String, Object>>> exportData(
            @AuthenticationPrincipal UUID userId) {
        Map<String, Object> data = backupService.exportData(userId);
        return ResponseEntity.ok(ApiResponse.success("备份已创建", data));
    }

    @PostMapping("/import")
    public ResponseEntity<ApiResponse<Map<String, Object>>> importData(
            @AuthenticationPrincipal UUID userId,
            @RequestBody Map<String, Object> body) {
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) body.get("data");
        if (data == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, "备份数据不能为空"));
        }
        Map<String, Object> result = backupService.importData(userId, data);
        return ResponseEntity.ok(ApiResponse.success("数据已恢复", result));
    }
}