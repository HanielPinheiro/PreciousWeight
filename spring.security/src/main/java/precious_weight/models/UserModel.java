package precious_weight.models;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import precious_weight.controllers.LoginController;
import precious_weight.requests.LoginRequest;

import java.util.Set;
import java.util.UUID;

import static precious_weight.config.constants.*;

@Entity
@Table(name = UserTableName)
public class UserModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = UserTableFieldName_Id, nullable = false)
    private UUID userId;

    @Column(name = UserTableFieldName_Email, nullable = false, unique = true)
    private String email;

    @Column(name = UserTableFieldName_Password, nullable = false)
    @JsonIgnore
    private String password;

    @Column(name = UserTableFieldName_Organization, nullable = false)
    private String organization;

    @ManyToMany(cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    @JoinTable(
            name=UserRoleRelationshipTableName,
            joinColumns = @JoinColumn(name = UserTableFieldName_Id),
            inverseJoinColumns = @JoinColumn(name = RoleTableFieldName_Id)
    )
    private Set<RoleModel> roleModels;

    public UUID getUserId() {
        return userId;
    }
    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getEmail() {
        return email;
    }
    public void setEmail(String email) {
        this.email = email;
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

    public Set<RoleModel> getRoles() {
        return roleModels;
    }
    public void setRoles(Set<RoleModel> roleModels) {
        this.roleModels = roleModels;
    }

    public boolean isLoginCorrect(LoginRequest loginRequest, PasswordEncoder passwordEncoder) {
        return passwordEncoder.matches(loginRequest.getPassword(), this.password);
    }
}
