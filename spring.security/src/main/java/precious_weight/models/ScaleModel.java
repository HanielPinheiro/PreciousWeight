package precious_weight.models;

import jakarta.persistence.*;
import java.io.Serializable;
import java.sql.Blob;

import static precious_weight.config.constants.*;

@Entity
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

    @Column(name = ScaleTableFieldName_Image, nullable = true, unique = true)
    private Blob scaleImage;


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

    public Blob getScaleImage() {
        return scaleImage;
    }
    public void setScaleImage(Blob scaleImage) {
        this.scaleImage = scaleImage;
    }
}
