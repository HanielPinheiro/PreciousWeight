package precious_weight.models;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import org.hibernate.envers.Audited;

import java.io.Serializable;
import java.sql.Blob;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.Base64;

import static precious_weight.config.constants.*;

@Entity
@Audited
@Table(name = BabyTableName)
public class BabyModel implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = BabyTableFieldName_Id)
    private Integer babyId;

    @Column(name = BabyTableFieldName_Name)
    private String babyName;

    @Column(name = BabyTableFieldName_MotherName)
    private String babyMotherName;

    @Column(name = BabyTableFieldName_BirthDate)
    @JsonFormat(pattern = "yyyy-MM-dd", timezone = "America/Sao_Paulo")
    private LocalDate babyBirthDate;

    @Column(name = BabyTableFieldName_State)
    private Integer babyState;

    @Column(name = BabyTableFieldName_WeightHour)
    private String babyWeightHour;

    @Column(name = BabyTableFieldName_HospitalId, nullable = false, length = 255, unique = true)
    private String babyHospitalId;

    @Column(name = BabyTableFieldName_ImageText)
    private String babyImageText;

    @JsonIgnore
    @Column(name = BabyTableFieldName_Image, nullable = true, unique = true)
    private Blob babyImage;

    public String getBabyImageAs64() throws SQLException {
        if (babyImage == null) return "";
        int blobLength = (int) babyImage.length();
        byte[] blobAsBytes = babyImage.getBytes(1, blobLength);
        return Base64.getEncoder().encodeToString(blobAsBytes);
    }

    @Transient
    private ScaleModel assignedScale;

    public ScaleModel getAssignedScale() {
        return assignedScale;
    }

    public void setAssignedScale(ScaleModel assignedScale) {
        this.assignedScale = assignedScale;
    }

    public Integer getBabyId() {
        return babyId;
    }

    public void setBabyId(Integer babyId) {
        this.babyId = babyId;
    }

    public String getBabyName() { return babyName; }

    public void setBabyName(String name) {
        this.babyName = name;
    }

    public String getBabyMotherName() {
        return babyMotherName;
    }

    public void setBabyMotherName(String motherName) {
        this.babyMotherName = motherName;
    }

    public LocalDate getBabyBirthDate() { return babyBirthDate; }

    public void setBabyBirthDate(LocalDate birthDate) {
        this.babyBirthDate = birthDate;
    }

    public String getBabyHospitalId() {
        return babyHospitalId;
    }

    public void setBabyState(Integer state) {
        this.babyState = state;
    }

    public Integer getBabyState() {
        return babyState;
    }

    public void setBabyWeightHour(String weightHour) {
        this.babyWeightHour = weightHour;
    }

    public String getBabyWeightHour() {
        return babyWeightHour;
    }

    public void setBabyImageText(String imageText) {
        this.babyImageText = imageText;
    }

    public String getBabyImageText() {
        return babyImageText;
    }

    public void setBabyHospitalId(String babyHospitalId) {
        this.babyHospitalId = babyHospitalId;
    }

    public Blob getBabyImage() {
        return babyImage;
    }

    public void setBabyImage(Blob babyImage) {
        this.babyImage = babyImage;
    }
}
