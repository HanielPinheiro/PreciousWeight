package precious_weight.app.models;

import jakarta.persistence.*;
import org.hibernate.envers.Audited;

import java.io.Serializable;

import static precious_weight.config.system.GlobalConstants.*;

@Entity
@Audited
@Table(name = ScaleTableName)
public class ScaleModel implements Serializable {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = ScaleTableFieldName_Id, nullable = false)
    private Integer scaleId;

    @Column(name = ScaleTableFieldName_Hash, nullable = false, length = 255, unique = true)
    private String scaleHash;

    @Column(name = ScaleTableFieldName_State, nullable = false)
    private Integer scaleState;

    @Column(name = BabyTableFieldName_Id, nullable = true)
    private Integer babyId;

    @Transient
    private BabyModel assignedBaby;

    public BabyModel getAssignedBaby() {
        return assignedBaby;
    }

    public void setAssignedBaby(BabyModel assignedBaby) {
        this.assignedBaby = assignedBaby;
    }
    public Integer getScaleId() {
        return scaleId;
    }
    public void setScaleId(Integer scaleId) {
        this.scaleId = scaleId;
    }

    public String getScaleHash() {
        return scaleHash;
    }
    public void setScaleHash(String scaleHash) {
        this.scaleHash = scaleHash;
    }

    public Integer getScaleState() {
        return scaleState;
    }
    public void setScaleState(Integer scaleState) {
        this.scaleState = scaleState;
    }

    public Integer getBabyId() {
        return babyId;
    }
    public void setBabyId(Integer id) {
        this.babyId = id;
    }

    public void FromJson(String mqttJson){

    }

}


