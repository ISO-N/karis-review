package top.kariscode.karisreview.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class RegisterRequest {

    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式无效")
    private String email;

    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 128, message = "密码长度需在6-128位之间")
    private String password;

    private String inviteCode;

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getInviteCode() { return inviteCode; }
    public void setInviteCode(String inviteCode) { this.inviteCode = inviteCode; }
}