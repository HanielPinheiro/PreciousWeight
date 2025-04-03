package precious_weight.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import precious_weight.models.BabyModel;
import precious_weight.models.ScaleModel;
import precious_weight.services.BabyService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.sql.rowset.serial.SerialBlob;
import java.io.IOException;
import java.sql.Blob;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Optional;

import static precious_weight.config.constants.*;

@RestController
@RequestMapping(BabyControllerName)
public class BabyController {

    @Autowired
    private BabyService babyService;

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_List)
    public List<BabyResponse> listAll() throws SQLException {
        List<BabyResponse> returns = new ArrayList<>();
        List<BabyModel> all = babyService.listAll();
        for (BabyModel babyModel : all) {
            BabyResponse element = new BabyResponse();
            element.CopyFrom(babyModel);
            returns.add(element);
        }
        return returns;
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Search)
    public ResponseEntity<BabyModel> searchById(@PathVariable Integer id) {
        Optional<BabyModel> baby = babyService.searchById(id);
        return baby.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Save)
    public BabyModel save(@RequestBody BabyModel babyModel) {
        return babyService.save(babyModel, null);
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(BabyControllerName_Update)
    public ResponseEntity<BabyModel> update(@PathVariable Integer id, @RequestBody BabyRequestModel request) {
        Optional<BabyModel> optionalBaby = babyService.searchById(id);

        if (optionalBaby.isEmpty()) return ResponseEntity.notFound().build();

        BabyModel babyModel = optionalBaby.get();
        babyModel.setBabyHash(request.getBabyHash());
        BabyModel updatedBabyModel = babyService.save(babyModel, request.getNewScaleId());
        return ResponseEntity.ok(updatedBabyModel);
    }

    @PreAuthorize("isAuthenticated()")
    @DeleteMapping(ControllerName_Delete)
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        babyService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Image)
    public ResponseEntity<String> uploadImage(@PathVariable Integer id, @RequestParam("file") MultipartFile file) {
        try {
            BabyModel babyModel = babyService.searchById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST));
            Blob scaleImage = new SerialBlob(file.getBytes());
            babyModel.setBabyImage(scaleImage);
            babyService.save(babyModel, null);
            return ResponseEntity.ok("Image Updated Successfully");
        } catch (IOException | SQLException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to upload image: " + e.getMessage());
        }
    }


    public static class BabyRequestModel {
        private String babyHash;
        private Integer newScaleId;

        public String getBabyHash() {
            return babyHash;
        }

        public void setBabyHash(String babyHash) {
            this.babyHash = babyHash;
        }

        public Integer getNewScaleId() {
            return newScaleId;
        }

        public void setNewScaleId(Integer newScaleId) {
            this.newScaleId = newScaleId;
        }
    }

    public static class BabyResponse {
        private Integer babyId;
        private String babyHash;
        private String babyImageAsBase64;

        public BabyResponse() {
        }

        public Integer getBabyId() {
            return babyId;
        }

        public void setScaleId(Integer babyId) {
            this.babyId = babyId;
        }

        public String getBabyHash() {
            return babyHash;
        }

        public void setBabyHash(String babyHash) {
            this.babyHash = babyHash;
        }

        public String getBabyImageAsBase64() {
            return babyImageAsBase64;
        }

        public void setBabyImageAsBase64(String babyImageAsBase64) {
            this.babyImageAsBase64 = babyImageAsBase64;
        }

        public void CopyFrom(BabyModel model) throws SQLException {
            this.babyId = model.getBabyId();
            this.babyHash = model.getBabyHash();

            Blob scaleImage = model.getBabyImage();
            if (scaleImage != null) {
                int blobLength = (int) scaleImage.length();
                byte[] blobAsBytes = scaleImage.getBytes(1, blobLength);
                this.babyImageAsBase64 = Base64.getEncoder().encodeToString(blobAsBytes);
            }
        }
    }

}
