package precious_weight.models;

import jakarta.persistence.*;

import java.io.Serializable;
import java.time.LocalDateTime;

import static precious_weight.config.constants.*;

@Entity
@Table(name = ScaleLogsTableName)
public class ScaleLogModel implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = LogsFieldName_Id, nullable = false)
    private Integer logId;

    @Column(name = LogsFieldName_Date, nullable = false, unique = true)
    private LocalDateTime logDate;

    @Column(name = ScaleTableFieldName_Id, nullable = false)
    private Integer scaleId;

    @Column(name = ScaleTableFieldName_State, nullable = false)
    private Integer scaleState;

    @Column(name = ScaleFieldName_NewState, nullable = false)
    private Integer newScaleState;

    public Integer getLogId() {
        return logId;
    }

    public void setLogId(Integer logId) {
        this.logId = logId;
    }

    public LocalDateTime getLogDate() {
        return logDate;
    }

    public void setLogDate(LocalDateTime logDate) {
        this.logDate = logDate;
    }

    public Integer getScaleId() {
        return scaleId;
    }

    public void setScaleId(Integer scaleId) {
        this.scaleId = scaleId;
    }

    public Integer getScaleState() {
        return scaleState;
    }

    public void setScaleState(Integer scaleState) {
        this.scaleState = scaleState;
    }

    public Integer getNewScaleState() {
        return newScaleState;
    }

    public void setNewScaleState(Integer newScaleState) {
        this.newScaleState = newScaleState;
    }
}
