package precious_weight.controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import precious_weight.models.RoleModel;
import precious_weight.interfaces.iUser;

import java.time.Instant;
import java.util.stream.Collectors;

@RestController
public class LoginController {

    private final JwtEncoder jwtEncoder;
    private final iUser iUser;
    private final BCryptPasswordEncoder passwordEncoder;

    public LoginController(JwtEncoder jwtEncoder,
                           iUser iUser,
                           BCryptPasswordEncoder passwordEncoder) {
        this.jwtEncoder = jwtEncoder;
        this.iUser = iUser;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest loginRequest) {

        var user = iUser.findByEmail(loginRequest.username);

        if (user.isEmpty() || !user.get().isLoginCorrect(loginRequest, passwordEncoder)) {
            throw new BadCredentialsException("user or password is invalid!");
        }

        var now = Instant.now();
        var expiresIn = 300L;

        var scopes = user.get().getRoles()
                .stream()
                .map(RoleModel::getName)
                .collect(Collectors.joining(" "));

        var claims = JwtClaimsSet.builder()
                .issuer("precious_weight_backend")
                .subject(user.get().getUserId().toString())
                .issuedAt(now)
                .expiresAt(now.plusSeconds(expiresIn))
                .claim("scope", scopes)
                .build();

        var jwtValue = jwtEncoder.encode(JwtEncoderParameters.from(claims)).getTokenValue();

        return ResponseEntity.ok(new LoginResponse(jwtValue, expiresIn));
    }

    public static class LoginRequest {
        private String username;
        private String password;

        // Default constructor
        public LoginRequest() {
        }

        // Parameterized constructor
        public LoginRequest(String username, String password) {
            this.username = username;
            this.password = password;
        }

        // Getters and setters
        public String getUsername() {
            return username;
        }

        public void setUsername(String username) {
            this.username = username;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }
    }

    public static class LoginResponse {
        private String accessToken;
        private Long  expiresIn;

        // Default constructor
        public LoginResponse() {
        }

        // Parameterized constructor
        public LoginResponse(String accessToken, Long expiresIn) {
            this.accessToken = accessToken;
            this.expiresIn = expiresIn;
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
    }
}