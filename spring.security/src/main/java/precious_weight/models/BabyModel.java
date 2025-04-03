package precious_weight.models;

import jakarta.persistence.*;

import java.io.Serializable;
import java.sql.Blob;

import static precious_weight.config.constants.*;

@Entity
@Table(name = BabyTableName)
public class BabyModel implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = BabyTableFieldName_Id)
    private Integer babyId;

    @Column(name = BabyTableFieldName_Hash, nullable = false, length = 255, unique = true)
    private String babyHash;

    @Column(name = BabyTableFieldName_Image, nullable = true, unique = true)
    private Blob babyImage;

    public Integer getBabyId() {
        return babyId;
    }

    public void setBabyId(Integer babyId) {
        this.babyId = babyId;
    }

    public String getBabyHash() {
        return babyHash;
    }

    public void setBabyHash(String babyHash) {
        this.babyHash = babyHash;
    }

    public Blob getBabyImage() {
        return babyImage;
    }

    public void setBabyImage(Blob babyImage) {
        this.babyImage = babyImage;
    }
}
