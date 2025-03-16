package precious_weight.models;

import jakarta.persistence.*;
import java.io.Serializable;

@Entity
@Table(name = "paciente")
public class BabyModel implements Serializable {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer idPaciente;

    @Column(nullable = false, length = 255)
    private String hashPaciente;

    public Integer getIdPaciente() {
        return idPaciente;
    }

    public void setIdPaciente(Integer idPaciente) {
        this.idPaciente = idPaciente;
    }

    public String getHashPaciente() {
        return hashPaciente;
    }

    public void setHashPaciente(String hashPaciente) {
        this.hashPaciente = hashPaciente;
    }
}
