package top.kariscode.karisreview.settings.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public class UpdateSettingsRequest {

    @NotNull(message = "{validation.settings.refresh.notnull}")
    @Pattern(regexp = "^([01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d$", message = "{validation.settings.refresh.pattern}")
    private String refreshTime;

    public String getRefreshTime() { return refreshTime; }
    public void setRefreshTime(String refreshTime) { this.refreshTime = refreshTime; }
}