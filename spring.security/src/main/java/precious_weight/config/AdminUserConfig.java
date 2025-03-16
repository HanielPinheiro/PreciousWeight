package precious_weight.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import precious_weight.models.RoleModel;
import precious_weight.models.UserModel;
import precious_weight.interfaces.iRole;
import precious_weight.interfaces.iUser;

import java.util.Set;

@Configuration
public class AdminUserConfig implements CommandLineRunner {

    private final iRole iRole;
    private final iUser iUser;
    private final BCryptPasswordEncoder passwordEncoder;

    public AdminUserConfig(iRole iRole,
                           iUser iUser,
                           BCryptPasswordEncoder passwordEncoder) {
        this.iRole = iRole;
        this.iUser = iUser;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {

        var roleAdmin = iRole.findByName(RoleModel.Values.ADMIN.name());
        roleAdmin.ifPresentOrElse(
                role -> {
                    System.out.println("nothing happen");
                },
                () -> {
                    // Create and save roles
                    RoleModel adminRoleModel = new RoleModel();
                    adminRoleModel.setName(RoleModel.Values.ADMIN.name());
                    iRole.save(adminRoleModel);

                    RoleModel basicRoleModel = new RoleModel();
                    basicRoleModel.setName(RoleModel.Values.BASIC.name());
                    iRole.save(basicRoleModel);
                }
        );

        var userAdmin = iUser.findByEmail("admin@precious_weight.com");
        var roleOfAdmin = iRole.findByName(RoleModel.Values.ADMIN.name())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST));
        userAdmin.ifPresentOrElse(
                userModel -> {
                    System.out.println("nothing happen");
                },
                () -> {
                    var user = new UserModel();
                    user.setEmail("admin@precious_weight.com");
                    user.setPassword(passwordEncoder.encode("M1U1tr4H4rdPa550w0rd!"));
                    user.setOrganization("Precious Weight");
                    user.setRoles(Set.of(roleOfAdmin));
                    iUser.save(user);
                }
        );
    }
}