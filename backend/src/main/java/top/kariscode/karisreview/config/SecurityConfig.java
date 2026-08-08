package top.kariscode.karisreview.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.MessageSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import top.kariscode.karisreview.common.dto.ApiResponse;
import top.kariscode.karisreview.config.ProtobufHttpMessageConverter;
import top.kariscode.karisreview.proto.KarisReviewProto.ApiError;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.util.Locale;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final MessageSource messageSource;
    private final ObjectMapper objectMapper;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter,
                          MessageSource messageSource,
                          ObjectMapper objectMapper) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.messageSource = messageSource;
        this.objectMapper = objectMapper;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> {})
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(
                    "/api/auth/config",
                    "/api/auth/register",
                    "/api/auth/register-code",
                    "/api/auth/login",
                    "/api/auth/password/reset-code",
                    "/api/auth/password/reset",
                    "/v3/api-docs/**",
                    "/swagger-ui/**",
                    "/swagger-ui.html"
                ).permitAll()
                .anyRequest().authenticated()
            )
            .exceptionHandling(ex -> ex.authenticationEntryPoint((request, response, authException) -> {
                response.setStatus(401);
                Locale locale = request.getLocale();
                String message = messageSource.getMessage("auth.unauthorized", null, "auth.unauthorized", locale);
                String accept = request.getHeader("Accept");
                if (accept != null && accept.contains(ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF_VALUE)) {
                    response.setContentType(ProtobufHttpMessageConverter.APPLICATION_X_PROTOBUF_VALUE);
                    ApiError.newBuilder()
                            .setCode(401)
                            .setMessage(message)
                            .build()
                            .writeTo(response.getOutputStream());
                } else {
                    // 与 GlobalExceptionHandler 同一格式：经 ObjectMapper 序列化 ApiResponse
                    // （架构评审 B4：原手拼字符串不转义，i18n 文案含引号/反斜杠即产生非法 JSON）。
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.setCharacterEncoding("UTF-8");
                    objectMapper.writeValue(response.getWriter(), ApiResponse.error(401, message));
                }
            }))
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}