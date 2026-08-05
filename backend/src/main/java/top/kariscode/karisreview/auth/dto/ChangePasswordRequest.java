package top.kariscode.karisreview.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class ChangePasswordRequest {

    @NotBlank(message = "{validation.password.notblank}")
    private String currentPassword;

    @NotBlank(message = "{validation.password.notblank}")
    @Size(min = 6, max = 128, message = "{validation.password.length}")
    private String newPassword;

    public String getCurrentPassword() { return currentPassword; }
    public void setCurrentPassword(String currentPassword) { this.currentPassword = currentPassword; }
    public String getNewPassword() { return newPassword; }
    public void setNewPassword(String newPassword) { this.newPassword = newPassword; }
}
