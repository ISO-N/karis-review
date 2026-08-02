package top.kariscode.karisreview.common.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.config.ProtobufHttpMessageConverter;
import top.kariscode.karisreview.proto.KarisReviewProto.ApiError;

import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<?> handleBusinessException(BusinessException e, HttpServletRequest request) {
        int status = e.getCode() >= 500 ? 500 : e.getCode();
        return error(status, e.getCode(), e.getMessage(), request);
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<?> handleBadCredentials(BadCredentialsException e, HttpServletRequest request) {
        return error(401, 401, "邮箱或密码错误", request);
    }

    @ExceptionHandler(UsernameNotFoundException.class)
    public ResponseEntity<?> handleUserNotFound(UsernameNotFoundException e, HttpServletRequest request) {
        return error(401, 401, "邮箱或密码错误", request);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<?> handleValidation(MethodArgumentNotValidException e, HttpServletRequest request) {
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .collect(Collectors.joining(", "));
        return error(400, 400, message, request);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<?> handleNotFound(NoResourceFoundException e, HttpServletRequest request) {
        return error(404, 404, "资源不存在", request);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleException(Exception e, HttpServletRequest request) {
        log.error("Unexpected error", e);
        return error(500, 500, "服务器内部错误", request);
    }

    private ResponseEntity<?> error(int httpStatus, int code, String message, HttpServletRequest request) {
        if (acceptsProtobuf(request)) {
            ApiError body = ApiError.newBuilder()
                    .setCode(code)
                    .setMessage(message)
                    .build();
            return ResponseEntity.status(httpStatus)
                    .contentType(ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF)
                    .body(body);
        }
        return ResponseEntity.status(httpStatus).body(ApiResponse.error(code, message));
    }

    private boolean acceptsProtobuf(HttpServletRequest request) {
        String accept = request.getHeader("Accept");
        return accept != null && accept.contains("application/x-protobuf");
    }
}
