package top.kariscode.karisreview.sync.controller;

import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.config.ProtobufHttpMessageConverter;
import top.kariscode.karisreview.proto.KarisReviewProto;
import top.kariscode.karisreview.sync.dto.BootstrapResponse;
import top.kariscode.karisreview.sync.service.SyncProtoMapper;
import top.kariscode.karisreview.sync.service.SyncService;

import java.util.UUID;

@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/sync")
public class SyncController {

    private final SyncService syncService;
    private final SyncProtoMapper protoMapper;

    public SyncController(SyncService syncService, SyncProtoMapper protoMapper) {
        this.syncService = syncService;
        this.protoMapper = protoMapper;
    }

    @GetMapping(value = "/bootstrap", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<BootstrapResponse>> bootstrap(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(name = "event_cursor", defaultValue = "0") long eventCursor) {
        return ResponseEntity.ok(ApiResponse.success(
                syncService.getBootstrap(userId, eventCursor)));
    }

    @GetMapping(value = "/bootstrap", produces = ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF_VALUE)
    public ResponseEntity<KarisReviewProto.SyncResponse> bootstrapProto(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(name = "event_cursor", defaultValue = "0") long eventCursor) {
        BootstrapResponse response = syncService.getBootstrap(userId, eventCursor);
        return ResponseEntity.ok(protoMapper.toProto(response));
    }
}
