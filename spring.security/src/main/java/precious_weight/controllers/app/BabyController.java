package precious_weight.controllers.app;

import precious_weight.app.models.BabyModel;
import precious_weight.app.services.BabyService;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;
import java.util.Map;

import static precious_weight.config.system.ApiConstants.*;

@RestController
@RequestMapping(BabyController)
public class BabyController {
    @Autowired
    private BabyService babyService;

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_List)
    public ResponseEntity<?> listAll() throws SQLException {
        try {
            return ResponseEntity.ok(babyService.listAll());
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Search)
    public ResponseEntity<?> searchById(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(babyService.searchById(id));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Save)
    public ResponseEntity<?> save(@RequestBody BabyModel babyModel) {
        try {
            return ResponseEntity.ok(babyService.save(babyModel));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Image)
    public ResponseEntity<?> uploadImage(@PathVariable Integer id, @RequestParam("file") MultipartFile file) {
        try {
            babyService.uploadImage(id, file);
            return ResponseEntity.ok("Image Updated Successfully");
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Enable)
    public ResponseEntity<?> enableBaby(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(babyService.enableOrDisable(id, true));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Disable)
    public ResponseEntity<?> disableBaby(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(babyService.enableOrDisable(id, false));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Update)
    public ResponseEntity<?> update(@PathVariable Integer id, @RequestBody BabyModel request) {
        try {
            return ResponseEntity.ok(babyService.update(id, request));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }
}


