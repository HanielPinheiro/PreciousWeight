package precious_weight.models;

import jakarta.persistence.*;

import java.io.Serializable;
import java.time.LocalDateTime;

import static precious_weight.config.constants.*;

@Entity
@Table(name = WeightTableName)
public class WeightModel implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = WeightTableFieldName_Id, nullable = false)
    private Integer weightId;

    @Column(name = WeightTableFieldName_Date, nullable = false)
    private LocalDateTime weightDate;

    @Column(name = ScaleTableFieldName_Id, nullable = false)
    private Integer scaleId;

    @Column(name = BabyTableFieldName_Id, nullable = false)
    private Integer babyId;

    @Column(name = WeightTableFieldName_Value, nullable = false)
    private Integer weightValue;

    public Integer getWeightId() {
        return weightId;
    }
    public void setWeightId(Integer weightId) {
        this.weightId = weightId;
    }

    public LocalDateTime getWeightDate() {
        return weightDate;
    }
    public void setWeightDate(LocalDateTime weightDate) {
        this.weightDate = weightDate;
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

    public Integer getWeightValue() {
        return weightValue;
    }
    public void setWeightValue(Integer weightValue) {
        this.weightValue = weightValue;
    }
}
