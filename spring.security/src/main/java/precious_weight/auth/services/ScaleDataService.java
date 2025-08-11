package precious_weight.auth.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import precious_weight.auth.interfaces.iScaleData;
import precious_weight.auth.models.ScaleDataModel;
import precious_weight.auth.models.request.ScaleDataRequest;

import java.security.SecureRandom;
import java.util.*;

@Service
public class ScaleDataService {
    @Autowired
    private iScaleData iScaleData;

    public ScaleDataModel NewScaleData(ScaleDataRequest scaleData) {
        ScaleDataModel model = new ScaleDataModel();
//        model.setMac(scaleData.getMac());
//        model.setPop(generatePop());
//
//        model = iScaleData.save(model);
//        model.getScaleId();
//
//        //gerar qr code
//        //colocar qrcode no db
//        //salvar de novo
//
//        model.setQrCode("asd");
        return iScaleData.save(model);
    }

    public ScaleDataModel UpdateScaleData(ScaleDataRequest scaleData) {
        ScaleDataModel model = iScaleData.getReferenceById(scaleData.getId());
//        model.setMac(scaleData.getMac());
//        model.setPop(generatePop());
//        model = iScaleData.save(model);
//        model.getScaleId();
//
//        //gerar qr code
//        //colocar qrcode no db
//        //salvar de novo
//
//        model.setQrCode("asd");
        return iScaleData.save(model);
    }


    public List<ScaleDataModel> GetScales() {
        return iScaleData.findAll();
    }

    public ScaleDataModel GetScaleFromId(UUID scaleId) {
        return GetScales().stream().filter(model -> model.getScaleId().equals(scaleId)).findFirst().orElse(null);
    }

    public ScaleDataModel GetScaleFromMac(String scaleMac) {
        return GetScales().stream().filter(model -> model.getMac().equals(scaleMac)).findFirst().orElse(null);
    }

    private String generatePop() {
        String ALPHANUMERIC = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@$%*+-./: ";
        int size =ALPHANUMERIC.length();
        SecureRandom random = new SecureRandom();
            StringBuilder sb = new StringBuilder(8);
            for (int i = 0; i < 8; i++) sb.append(ALPHANUMERIC.charAt(random.nextInt(size)));
            return sb.toString();
    }

}
