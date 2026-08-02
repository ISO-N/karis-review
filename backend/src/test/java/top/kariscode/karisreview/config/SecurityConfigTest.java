package top.kariscode.karisreview.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import top.kariscode.karisreview.auth.controller.AuthController;
import top.kariscode.karisreview.auth.dto.AuthConfigResponse;
import top.kariscode.karisreview.auth.dto.LoginRequest;
import top.kariscode.karisreview.auth.dto.LoginResponse;
import top.kariscode.karisreview.auth.dto.RegisterRequest;
import top.kariscode.karisreview.auth.service.AuthService;
import top.kariscode.karisreview.common.etag.UserEtagService;
import top.kariscode.karisreview.deck.controller.DeckController;
import top.kariscode.karisreview.deck.service.DeckService;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest({AuthController.class, DeckController.class})
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JacksonConfig.class})
class SecurityConfigTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private DeckService deckService;

    @MockitoBean
    private UserEtagService etagService;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    void protectedEndpointRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/decks"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401))
                .andExpect(jsonPath("$.message").value("未登录或Token已过期"));
    }

    @Test
    void invalidBearerTokenReturns401() throws Exception {
        mockMvc.perform(get("/api/decks")
                        .header("Authorization", "Bearer invalid-token"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void authConfigIsPermittedWithoutAuthentication() throws Exception {
        when(authService.getAuthConfig()).thenReturn(new AuthConfigResponse(false));

        mockMvc.perform(get("/api/auth/config"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.invite_code_required").value(false));
    }

    @Test
    void registerIsPermittedWithoutAuthentication() throws Exception {
        UUID userId = UUID.randomUUID();
        when(authService.register(any(RegisterRequest.class)))
                .thenReturn(new LoginResponse("token", userId, "user@example.com"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"user@example.com","password":"password123"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token").value("token"));
    }

    @Test
    void loginIsPermittedWithoutAuthentication() throws Exception {
        UUID userId = UUID.randomUUID();
        when(authService.login(any(LoginRequest.class)))
                .thenReturn(new LoginResponse("token", userId, "user@example.com"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"user@example.com","password":"password123"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token").value("token"));
    }
}
