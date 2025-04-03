package precious_weight.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import precious_weight.models.RoleModel;
import precious_weight.models.UserModel;
import precious_weight.interfaces.iRole;
import precious_weight.interfaces.iUser;

import java.util.List;
import java.util.Set;

import static precious_weight.config.constants.UserControllerName;
import static precious_weight.config.constants.UserControllerName_New;
import static precious_weight.config.constants.ControllerName_List;

@RestController
@RequestMapping(UserControllerName)
public class UserController {

    private final iUser iUser;
    private final iRole iRole;
    private final BCryptPasswordEncoder passwordEncoder;

    public UserController(iUser iUser,
                          iRole iRole,
                          BCryptPasswordEncoder passwordEncoder) {
        this.iUser = iUser;
        this.iRole = iRole;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    @PostMapping(UserControllerName_New)
    @PreAuthorize("hasAuthority('SCOPE_ADMIN')")
    public ResponseEntity<Void> newUser(@RequestBody UserRequest request) {
        var basicRole = iRole.findByName(RoleModel.Values.BASIC.name()).orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST));

        var userFromDb = iUser.findByEmail(request.username);
        if (userFromDb.isPresent()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST);

        var user = new UserModel();
        user.setEmail(request.username);
        user.setPassword(passwordEncoder.encode(request.password));
        user.setOrganization(request.organization);
        user.setRoles(Set.of(basicRole));

        iUser.save(user);

        return ResponseEntity.ok().build();
    }

    @PostMapping(ControllerName_List)
    @PreAuthorize("hasAuthority('SCOPE_ADMIN')")
    public ResponseEntity<List<UserModel>> listUsers() {
        var users = iUser.findAll();
        return ResponseEntity.ok(users);
    }

    public static class UserRequest {
        private String username;
        private String password;
        private String organization;

        // Default constructor (required for deserialization)
        public UserRequest() {
        }

        // Parameterized constructor
        public UserRequest(String username, String password, String organization) {
            this.username = username;
            this.password = password;
            this.organization = organization;
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

        public String getOrganization() {
            return organization;
        }
        public void setOrganization(String organization) {
            this.organization = organization;
        }
    }
}

