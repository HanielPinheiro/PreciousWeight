package precious_weight.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import precious_weight.models.BabyModel;
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
            return ResponseEntity.ok(babyService.save(babyModel, null));
        }
        catch(Exception ex){
            return ResponseEntity.badRequest().build();
        }
    }

//    @PreAuthorize("isAuthenticated()")
//    @PostMapping(BabyControllerName_Update)
//    public ResponseEntity<BabyModel> update(@PathVariable Integer id, @RequestBody RelBabyToScaleModel request) {
//        Optional<BabyModel> optionalBaby = babyService.searchById(id);
//
//        if (optionalBaby.isEmpty()) return ResponseEntity.notFound().build();
//
//        BabyModel babyModel = optionalBaby.get();
//        babyModel.setBabyHospitalId(request.getBabyHash());
//        BabyModel updatedBabyModel = babyService.save(babyModel, request.getNewScaleId());
//        return ResponseEntity.ok(updatedBabyModel);
//    }

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

}


