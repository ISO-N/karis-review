package top.kariscode.karisreview.auth.dto;

import java.util.UUID;

public class LoginResponse {

    private String token;
    private UserInfo user;

    public LoginResponse(String token, UUID id, String email) {
        this.token = token;
        this.user = new UserInfo(id, email);
    }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
    public UserInfo getUser() { return user; }
    public void setUser(UserInfo user) { this.user = user; }

    public static class UserInfo {
        private UUID id;
        private String email;

        public UserInfo(UUID id, String email) {
            this.id = id;
            this.email = email;
        }

        public UUID getId() { return id; }
        public void setId(UUID id) { this.id = id; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }
}