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
    @Column(name = LogsFieldName_Id, nullable = false)
    private Integer logId;

    @Column(name = LogsFieldName_Date, nullable = false, unique = true)
    private LocalDateTime logDate;

    @Column(name = BabyTableFieldName_Id, nullable = false)
    private Integer babyId;

    @Column(name = ScaleTableFieldName_Id, nullable = true)
    private Integer scaleId;

    @Column(name = BabyLogsFieldName_NewId, nullable = false)
    private Integer newScaleId;



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

    public Integer getBabyId() {
        return babyId;
    }

    public void setBabyId(Integer babyId) {
        this.babyId = babyId;
    }

    public Integer getScaleId() {
        return scaleId;
    }

    public void setScaleId(Integer scaleId) {
        this.scaleId = scaleId;
    }

    public Integer getNewScaleId() {
        return newScaleId;
    }

    public void setNewScaleId(Integer newScaleId) {
        this.newScaleId = newScaleId;
    }
}
