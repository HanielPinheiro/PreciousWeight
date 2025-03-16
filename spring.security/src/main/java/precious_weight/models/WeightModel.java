package precious_weight.models;

import jakarta.persistence.*;
import java.io.Serializable;
import java.time.LocalDateTime;

@Entity
@Table(name = "peso")
public class WeightModel implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer idPeso;

    @Column(nullable = false)
    private LocalDateTime dataPeso;

    @ManyToOne
    @JoinColumn(name = "id_balanca", nullable = false)
    private ScaleModel scaleModel;

    @ManyToOne
    @JoinColumn(name = "id_paciente", nullable = false)
    private BabyModel babyModel;

    @Column(nullable = false)
    private Integer peso;

    public Integer getIdPeso() {
        return idPeso;
    }

    public void setIdPeso(Integer idPeso) {
        this.idPeso = idPeso;
    }

    public LocalDateTime getDataPeso() {
        return dataPeso;
    }

    public void setDataPeso(LocalDateTime dataPeso) {
        this.dataPeso = dataPeso;
    }

    public ScaleModel getBalanca() {
        return scaleModel;
    }

    public void setBalanca(ScaleModel scaleModel) {
        this.scaleModel = scaleModel;
    }

    public BabyModel getPaciente() {
        return babyModel;
    }

    public void setPaciente(BabyModel babyModel) {
        this.babyModel = babyModel;
    }

    public Integer getPeso() {
        return peso;
    }

    public void setPeso(Integer peso) {
        this.peso = peso;
    }
}
