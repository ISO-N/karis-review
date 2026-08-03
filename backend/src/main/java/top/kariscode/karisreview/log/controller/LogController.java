package top.kariscode.karisreview.log.controller;

import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.log.dto.UserLogResponse;
import top.kariscode.karisreview.log.service.UserLogService;

import java.util.UUID;

@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/logs")
public class LogController {

    private final UserLogService userLogService;

    public LogController(UserLogService userLogService) {
        this.userLogService = userLogService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Page<UserLogResponse>>> getLogs(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size,
            @RequestParam(required = false) String level,
            @RequestParam(required = false) String category) {
        Page<UserLogResponse> logs = userLogService.getLogs(userId, level, category, page, size);
        return ResponseEntity.ok(ApiResponse.success(logs));
    }
}