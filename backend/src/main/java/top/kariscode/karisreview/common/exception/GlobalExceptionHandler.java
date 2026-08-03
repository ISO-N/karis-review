package top.kariscode.karisreview.common.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
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

import java.util.Locale;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);
    private final MessageSource messageSource;

    public GlobalExceptionHandler(MessageSource messageSource) {
        this.messageSource = messageSource;
    }

    private String resolve(String key, HttpServletRequest request, Object... args) {
        Locale locale = request != null
                ? request.getLocale()
                : LocaleContextHolder.getLocale();
        try {
            return messageSource.getMessage(key, args, key, locale);
        } catch (Exception e) {
            return key;
        }
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<?> handleBusinessException(BusinessException e, HttpServletRequest request) {
        int status = e.getCode() >= 500 ? 500 : e.getCode();
        String message;
        if (e.getMessageKey() != null) {
            message = resolve(e.getMessageKey(), request, e.getArgs() != null ? e.getArgs() : new Object[0]);
        } else {
            message = e.getMessage();
        }
        return error(status, e.getCode(), message, request);
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<?> handleBadCredentials(BadCredentialsException e, HttpServletRequest request) {
        return error(401, 401, resolve("auth.email.password.wrong", request), request);
    }

    @ExceptionHandler(UsernameNotFoundException.class)
    public ResponseEntity<?> handleUserNotFound(UsernameNotFoundException e, HttpServletRequest request) {
        return error(401, 401, resolve("auth.email.password.wrong", request), request);
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
        return error(404, 404, resolve("server.resource.notfound", request), request);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleException(Exception e, HttpServletRequest request) {
        log.error("Unexpected error", e);
        return error(500, 500, resolve("server.error", request), request);
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
