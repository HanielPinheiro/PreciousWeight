package precious_weight.controllers.app;

import precious_weight.app.models.ScaleModel;
import precious_weight.app.services.ScaleService;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

import static precious_weight.config.system.ApiConstants.*;

@RestController
@RequestMapping(ScaleController)
public class ScaleController {

    @Autowired
    private ScaleService scaleService;

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_List)
    public ResponseEntity<?> listAll() {
        try {
            return ResponseEntity.ok(scaleService.GetScales());
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Search)
    public ResponseEntity<?> getById(@PathVariable Integer id) {
        try {
            ScaleModel data = scaleService.GetScaleFromId(id);
            return data != null ? ResponseEntity.ok(data) : ResponseEntity.badRequest().build();
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_SetScaleToUser)
    public ResponseEntity<?> scaleToUser(@PathVariable String scaleHash) {
        try {
            return ResponseEntity.ok(scaleService.SetScaleToUser(scaleHash));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Update)
    public ResponseEntity<?> updateHash(@PathVariable Integer id, @RequestBody ScaleModel model) {
        try {
            return ResponseEntity.ok(scaleService.UpdateHash(id, model));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Enable)
    public ResponseEntity<?> enableScale(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(scaleService.EnableOrDisable(id, true));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Disable)
    public ResponseEntity<?> disableScale(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(scaleService.EnableOrDisable(id, false));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_SetBaby)
    public ResponseEntity<?> setBaby(@RequestBody ScaleModel model) {
        try {
            return ResponseEntity.ok(scaleService.SetOrUnset(model, true));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_UnsetBaby)
    public ResponseEntity<?> unsetBaby(@RequestBody ScaleModel model) {
        try {
            return ResponseEntity.ok(scaleService.SetOrUnset(model, false));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }
}


