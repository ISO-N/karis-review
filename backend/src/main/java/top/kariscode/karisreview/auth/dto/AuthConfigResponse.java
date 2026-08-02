package top.kariscode.karisreview.auth.dto;

public class AuthConfigResponse {

    private final boolean inviteCodeRequired;

    public AuthConfigResponse(boolean inviteCodeRequired) {
        this.inviteCodeRequired = inviteCodeRequired;
    }

    public boolean isInviteCodeRequired() {
        return inviteCodeRequired;
    }
}
