package top.kariscode.karisreview.settings.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public class UpdateSettingsRequest {

    @NotNull(message = "刷新时间不能为空")
    @Pattern(regexp = "^([01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d$", message = "刷新时间格式必须为有效的 HH:mm:ss")
    private String refreshTime;

    public String getRefreshTime() { return refreshTime; }
    public void setRefreshTime(String refreshTime) { this.refreshTime = refreshTime; }
}