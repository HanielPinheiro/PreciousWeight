package precious_weight.models;

import jakarta.persistence.*;
import java.io.Serializable;
import java.time.LocalDateTime;

@Entity
@Table(name = "log_balanca")
public class ScaleLogModel implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer idLog;

    @Column(nullable = false)
    private LocalDateTime dataLog;

    @ManyToOne
    @JoinColumn(name = "id_balanca", nullable = false)
    private ScaleModel scaleModel;

    @Column(nullable = false)
    private Integer estadoBalanca;

    @Column(nullable = false)
    private Integer novoEstadoBalanca;

    public Integer getIdLog() {
        return idLog;
    }

    public void setIdLog(Integer idLog) {
        this.idLog = idLog;
    }

    public LocalDateTime getDataLog() {
        return dataLog;
    }

    public void setDataLog(LocalDateTime dataLog) {
        this.dataLog = dataLog;
    }

    public ScaleModel getBalanca() {
        return scaleModel;
    }

    public void setBalanca(ScaleModel scaleModel) {
        this.scaleModel = scaleModel;
    }

    public Integer getEstadoBalanca() {
        return estadoBalanca;
    }

    public void setEstadoBalanca(Integer estadoBalanca) {
        this.estadoBalanca = estadoBalanca;
    }

    public Integer getNovoEstadoBalanca() {
        return novoEstadoBalanca;
    }

    public void setNovoEstadoBalanca(Integer novoEstadoBalanca) {
        this.novoEstadoBalanca = novoEstadoBalanca;
    }
}
