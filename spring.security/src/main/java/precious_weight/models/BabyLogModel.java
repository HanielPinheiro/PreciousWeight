package precious_weight.models;

import jakarta.persistence.*;
import java.io.Serializable;
import java.time.LocalDateTime;

import static precious_weight.config.constants.*;

@Entity
@Table(name = BabyLogsTableName)
public class BabyLogModel implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer idLog;

    @Column(nullable = false)
    private LocalDateTime dataLog;

    @ManyToOne(optional = false)
    @JoinColumn(name = BabyLogsFieldName_BabyId, nullable = false)
    private BabyModel babyModel;

    @ManyToOne(optional = true) 
    @JoinColumn(name = BabyLogsFieldName_ScaleId, nullable = true)
    private ScaleModel scaleModel;

    @Column(nullable = false)
    private Integer newScaleId;

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

    public BabyModel getPaciente() {
        return babyModel;
    }

    public void setPaciente(BabyModel babyModel) {
        this.babyModel = babyModel;
    }

    public ScaleModel getBalanca() {
        return scaleModel;
    }

    public void setBalanca(ScaleModel scaleModel) {
        this.scaleModel = scaleModel;
    }

    public Integer getNewScaleId() {
        return newScaleId;
    }

    public void setNewScaleId(Integer newScaleId) {
        this.newScaleId = newScaleId;
    }
}
