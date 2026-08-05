package top.kariscode.karisreview.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class SendRegisterCodeRequest {

    @NotBlank(message = "{validation.email.notblank}")
    @Email(message = "{validation.email.invalid}")
    private String email;

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}
