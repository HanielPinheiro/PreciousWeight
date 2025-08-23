package precious_weight.app.models.response;

import precious_weight.app.models.ScaleModel;

public class ScaleResponse {
    private Integer scaleId;
    private String scaleHash;
    private Integer scaleState;
    private Integer babyId;

    public ScaleResponse(){}

    public ScaleResponse(ScaleModel model) {
        this.scaleId = model.getScaleId();
        this.scaleHash = model.getScaleHash();
        this.scaleState = model.getScaleState();
        this.babyId = model.getAssignedBaby() != null ? model.getAssignedBaby().getBabyId() : null;
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

    public void setBabyId(Integer babyId) {
        this.babyId = babyId;
    }

    @Override
    public String toString() {
        return "ScaleResponse{" +
                "scaleId=" + scaleId +
                ", scaleHash='" + scaleHash + '\'' +
                ", scaleState=" + scaleState +
                ", babyId=" + babyId +
                '}';
    }
}
