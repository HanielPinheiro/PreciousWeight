package precious_weight.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import precious_weight.interfaces.iScaleLog;
import precious_weight.models.ScaleLogModel;
import precious_weight.models.ScaleModel;
import precious_weight.interfaces.iScale;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.sql.rowset.serial.SerialBlob;
import java.io.IOException;
import java.sql.Blob;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Optional;

import static precious_weight.config.constants.*;

@RestController
@RequestMapping(ScaleControllerName)
public class ScaleController {
    @Autowired
    private iScaleLog iScaleLog;

    @Autowired
    private iScale iScale;

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_List)
    public List<ScaleResponse> listAll() throws SQLException {
        List<ScaleResponse> returns = new ArrayList<>();
        List<ScaleModel> all = iScale.findAll();
        for (ScaleModel scaleModel : all) {
            ScaleResponse element = new ScaleResponse();
            element.CopyFrom(scaleModel);
            returns.add(element);
        }
        return returns;
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Search)
    public ResponseEntity<ScaleResponse> searchById(@PathVariable Integer id) throws SQLException {
        ScaleModel scale = iScale.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST));
        var result = new ScaleResponse();
        result.CopyFrom(scale);
        return ResponseEntity.ok(result);
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Save)
    public ScaleModel save(@RequestBody ScaleModel scaleModel) {
        Integer scaleId = scaleModel.getScaleId();
        if (scaleId == null) return iScale.save(scaleModel);

        Optional<ScaleModel> optionalScaleModel = iScale.findById(scaleId);
        if (optionalScaleModel.isPresent()) {
            Integer lastScaleState = optionalScaleModel.get().getScaleState();
            Integer newScaleState = scaleModel.getScaleState();

            if (!lastScaleState.equals(newScaleState)) {
                ScaleLogModel log = new ScaleLogModel();
                log.setLogDate(LocalDateTime.now());
                log.setScaleId(scaleId);
                log.setScaleState(lastScaleState);
                log.setNewScaleState(newScaleState);
                iScaleLog.save(log);
            }
        }

        return iScale.save(scaleModel);
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Image)
    public ResponseEntity<String> uploadImage(@PathVariable Integer id, @RequestParam("file") MultipartFile file) {
        try {
            ScaleModel scaleModel = iScale.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST));
            Blob scaleImage = new SerialBlob(file.getBytes());
            scaleModel.setScaleImage(scaleImage);
            iScale.save(scaleModel);
            return ResponseEntity.ok("Image Updated Successfully");
        } catch (IOException | SQLException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to upload image: " + e.getMessage());
        }
    }

    @PreAuthorize("isAuthenticated()")
    @DeleteMapping(ControllerName_Delete)
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        iScale.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    public static class ScaleResponse {
        private Integer scaleId;
        private String scaleHash;
        private Integer scaleState;
        private String scaleImageAsBase64;

        public ScaleResponse() {
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

        public String getScaleImageAsBase64() {
            return scaleImageAsBase64;
        }

        public void setScaleImageAsBase64(String scaleImageAsBase64) {
            this.scaleImageAsBase64 = scaleImageAsBase64;
        }

        public void CopyFrom(ScaleModel model) throws SQLException {
            this.scaleId = model.getScaleId();
            this.scaleHash = model.getScaleHash();
            this.scaleState = model.getScaleState();

            Blob scaleImage = model.getScaleImage();
            if (scaleImage != null) {
                int blobLength = (int) scaleImage.length();
                byte[] blobAsBytes = scaleImage.getBytes(1, blobLength);
                this.scaleImageAsBase64 = Base64.getEncoder().encodeToString(blobAsBytes);
            }
        }
    }
}
