package precious_weight.models;

import jakarta.persistence.*;

import static precious_weight.config.constants.RoleTableName;
import static precious_weight.config.constants.RoleTableFieldName_Id;
import static precious_weight.config.constants.RoleTableFieldName_Name;

@Entity
@Table(name = RoleTableName)
public class RoleModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = RoleTableFieldName_Id)
    private Long roleId;

    @Column(name = RoleTableFieldName_Name)
    private String name;

    public Long getRoleId() {
        return roleId;
    }

    public void setRoleId(Long roleId) {
        this.roleId = roleId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public enum Values{
        ADMIN(1L),
        BASIC(2L);

        final long roleId;

        Values(long roleId){
            this.roleId = roleId;
        }

        public long getRoleId() {
            return roleId;
        }
    }
}
