package top.kariscode.karisreview.common.exception;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.MessageSource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.log.service.UserLogService;
import top.kariscode.karisreview.proto.KarisReviewProto.ApiError;

import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GlobalExceptionHandlerTest {

    @Mock
    private MessageSource messageSource;

    @Mock
    private UserLogService userLogService;

    private GlobalExceptionHandler handler;

    @BeforeEach
    void setUp() {
        handler = new GlobalExceptionHandler(messageSource, Optional.of(userLogService));
        when(messageSource.getMessage(anyString(), any(), any(), any(Locale.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void businessExceptionReturnsUnifiedJsonResponse() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/test");

        ResponseEntity<?> response = handler.handleBusinessException(
                new BusinessException(404, "test.notfound"), request);

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        assertInstanceOf(ApiResponse.class, response.getBody());
        ApiResponse<?> body = (ApiResponse<?>) response.getBody();
        assertEquals(404, body.getCode());
        assertEquals("test.notfound", body.getMessage());
    }

    @Test
    void businessExceptionReturnsProtobufApiErrorWhenAccepted() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/test");
        request.addHeader("Accept", "application/x-protobuf");

        ResponseEntity<?> response = handler.handleBusinessException(
                new BusinessException(400, "test.invalid"), request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertInstanceOf(ApiError.class, response.getBody());
        ApiError body = (ApiError) response.getBody();
        assertEquals(400, body.getCode());
        assertEquals("test.invalid", body.getMessage());
    }

    @Test
    void serverErrorWritesDesensitizedUserLogForAuthenticatedUser() {
        UUID userId = UUID.randomUUID();
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(userId, null));
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/test");

        handler.handleException(new RuntimeException("boom"), request);

        verify(userLogService).report(
                eq(userId), eq("log.operation.server.error"), any(Map.class));
    }
}
