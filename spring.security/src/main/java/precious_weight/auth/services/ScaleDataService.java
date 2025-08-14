package precious_weight.auth.services;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import precious_weight.auth.interfaces.iScaleData;
import precious_weight.auth.models.ScaleDataModel;
import precious_weight.auth.models.request.ScaleDataRequest;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.security.SecureRandom;
import java.util.*;

@Service
public class ScaleDataService {
    @Autowired
    private iScaleData iScaleData;

    public ScaleDataModel NewScaleData(ScaleDataRequest scaleData) {
        ScaleDataModel model = new ScaleDataModel();
        model.setMac(scaleData.getMac());
        model.setPop(generatePop());

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
    public byte[] GetQrCodeFromId(UUID scaleId) {
        try {
            BufferedImage qrImage = generateQRCodeImage(scaleId.toString(), 250, 250);
            // Convert BufferedImage to byte array
            ByteArrayOutputStream arrayOfBytes = new ByteArrayOutputStream();
            ImageIO.write(qrImage, "PNG", arrayOfBytes);
            return arrayOfBytes.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate QR code", e);
        }
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

    private BufferedImage generateQRCodeImage(String data, int width, int height) throws Exception {
        QRCodeWriter qrCodeWriter = new QRCodeWriter();
        BitMatrix bitMatrix = qrCodeWriter.encode(data, BarcodeFormat.QR_CODE, width, height);

        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        for (int x = 0; x < width; x++) {
            for (int y = 0; y < height; y++) {
                image.setRGB(x, y, bitMatrix.get(x, y) ? 0x000000 : 0xFFFFFF);
            }
        }
        return image;
    }
}
