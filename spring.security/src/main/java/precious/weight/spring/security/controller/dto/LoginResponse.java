package precious.weight.spring.security.controller.dto;

public record LoginResponse(String accessToken, Long expiresIn) {
}