package top.kariscode.karisreview.config;

import org.springframework.context.MessageSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
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

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter, MessageSource messageSource) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.messageSource = messageSource;
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
                    "/api/auth/login",
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
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.setCharacterEncoding("UTF-8");
                    response.getWriter().write("{\"code\":401,\"message\":\"" + message + "\",\"data\":null}");
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