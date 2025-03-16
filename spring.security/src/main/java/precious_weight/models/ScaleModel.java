package precious_weight.models;

import jakarta.persistence.*;
import java.io.Serializable;

@Entity
@Table(name = "scale")
public class ScaleModel implements Serializable {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer scaleId;

    @Column(nullable = false, length = 255)
    private String scaleHash;

    @Column(nullable = false)
    private Integer scaleState;

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
}
