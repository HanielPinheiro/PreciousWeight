package precious_weight.auth.models.response;

import precious_weight.auth.models.ScaleDataModel;

import java.sql.Blob;
import java.util.UUID;

public class ScaleDataResponse {
    private UUID scaleId;
    private String mac;
    private String pop;
    private Blob qrCode;

    public ScaleDataResponse(ScaleDataModel model) {
        this.scaleId = model.getScaleId();
        this.mac = model.getMac();
        this.pop = model.getPop();
    }

    public void setQrCode(Blob qrCode) {this.qrCode = qrCode;}

}
