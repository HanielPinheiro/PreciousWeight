package precious_weight.response;

import precious_weight.models.UserModel;

public class LoginResponse {
    private String accessToken;
    private Long expiresIn;
    private UserModel user;

    // Parameterized constructor
    public LoginResponse(String accessToken, Long expiresIn, UserModel user) {
        this.accessToken = accessToken;
        this.expiresIn = expiresIn;
        this.user = user;
    }

    // Getters and setters
    public String getAccessToken() {
        return accessToken;
    }

    public void setAccessToken(String username) {
        this.accessToken = username;
    }

    public Long getExpiresIn() {
        return expiresIn;
    }

    public void setExpiresIn(Long expiresIn) {
        this.expiresIn = expiresIn;
    }

    public UserModel getUser() {
        return user;
    }

    public void setUser(UserModel expiresIn) {
        this.user = expiresIn;
    }
    }
