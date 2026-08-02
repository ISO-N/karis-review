package top.kariscode.karisreview.sync.dto;

import java.util.UUID;

public class BootstrapUser {

    private UUID id;
    private String email;
    private String refreshTime;

    public BootstrapUser() {}

    public BootstrapUser(UUID id, String email, String refreshTime) {
        this.id = id;
        this.email = email;
        this.refreshTime = refreshTime;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getRefreshTime() { return refreshTime; }
    public void setRefreshTime(String refreshTime) { this.refreshTime = refreshTime; }
}
