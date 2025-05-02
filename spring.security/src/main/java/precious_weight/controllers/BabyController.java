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
import java.util.List;
import java.util.Optional;

import static precious_weight.config.constants.*;

@RestController
@RequestMapping(BabyControllerName)
public class BabyController {

    @Autowired
    private BabyService babyService;

    /**
     * ====================================================================================
     * CREATE / READ
     * ===================================================================================
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_List)
    public ResponseEntity<List<BabyModel>> listAll() throws SQLException {
        try {
            return ResponseEntity.ok(babyService.listAll());
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Search)
    public ResponseEntity<BabyModel> searchById(@PathVariable Integer id) {
        Optional<BabyModel> baby = babyService.searchById(id);
        return baby.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Save)
    public ResponseEntity<BabyModel> save(@RequestBody BabyModel babyModel) {
        try {
            return ResponseEntity.ok(babyService.save(babyModel));
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * ====================================================================================
     * UPDATE  QR CODE
     * ===================================================================================
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Image)
    public ResponseEntity<String> uploadImage(@PathVariable Integer id, @RequestParam("file") MultipartFile file) {
        try {
            BabyModel babyModel = babyService.searchById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST));
            Blob scaleImage = new SerialBlob(file.getBytes());
            babyModel.setBabyImage(scaleImage);
            babyService.save(babyModel);
            return ResponseEntity.ok("Image Updated Successfully");
        } catch (IOException | SQLException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to upload image: " + e.getMessage());
        }
    }

    /**
     * ====================================================================================
     * UPDATE STATE -> ENABLE / DISABLE
     * ===================================================================================
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Enable)
    public ResponseEntity<BabyModel> enableBaby(@PathVariable Integer id) {
        try {
            return enableOrDisable(id, true);
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Disable)
    public ResponseEntity<BabyModel> disableBaby(@PathVariable Integer id) {
        try {
            return enableOrDisable(id, false);
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    private ResponseEntity<BabyModel> enableOrDisable(Integer babyId, boolean enabled) {
        // Verificar se existe balança vinculada ao bebe
        var babiesWithAndWithoutScales = babyService.listAll();
        var baby = babiesWithAndWithoutScales.stream().filter(s -> s.getBabyId().equals(babyId))
                .findFirst().orElse(null);

        // Se sim, retornar erro
        if (baby == null) return ResponseEntity.badRequest().build();
        if (baby.getAssignedScale() != null) return ResponseEntity.badRequest().build();

        // Se não, prosseguir com a ação
        var val = enabled ? BabyStates.enabled.value : BabyStates.disabled.value;
        baby.setBabyState(val);
        return ResponseEntity.ok(babyService.save(baby));
    }

    /**
     * ====================================================================================
     * UPDATE BABY DATA
     * ===================================================================================
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Update)
    public ResponseEntity<BabyModel> update(@PathVariable Integer id, @RequestBody BabyModel request) {
        try {
            Optional<BabyModel> optionalBaby = babyService.searchById(id);
            if (optionalBaby.isEmpty()) return ResponseEntity.notFound().build();

            BabyModel babyModel = optionalBaby.get();

            if (request.getBabyHospitalId() != null)
                babyModel.setBabyHospitalId(request.getBabyHospitalId());
            if (request.getBabyName() != null)
                babyModel.setBabyName(request.getBabyName());
            if (request.getBabyMotherName() != null)
                babyModel.setBabyMotherName(request.getBabyMotherName());
            if (request.getBabyBirthDate() != null)
                babyModel.setBabyBirthDate(request.getBabyBirthDate());
            if (request.getBabyImageText() != null)
                babyModel.setBabyImageText(request.getBabyImageText());

            return ResponseEntity.ok(babyService.save(babyModel));
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    public enum BabyStates {
        disabled(0), enabled(1);
        public final int value;

        BabyStates(int _value) {
            value = _value;
        }
    }
}


