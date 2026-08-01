package top.kariscode.karisreview.settings.dto;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

public class UserSettingsResponse {

    private String email;
    private String refreshTime;

    public UserSettingsResponse(String email, LocalTime refreshTime) {
        this.email = email;
        this.refreshTime = refreshTime.format(DateTimeFormatter.ofPattern("HH:mm:ss"));
    }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getRefreshTime() { return refreshTime; }
    public void setRefreshTime(String refreshTime) { this.refreshTime = refreshTime; }
}