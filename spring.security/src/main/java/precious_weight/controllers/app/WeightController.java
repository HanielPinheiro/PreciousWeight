package precious_weight.controllers.app;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import precious_weight.app.models.request.WeightRequest;
import precious_weight.app.services.WeightService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

import static precious_weight.config.system.ApiConstants.*;

@RestController
@RequestMapping(WeightController)
public class WeightController {

    @Autowired
    WeightService weightService;

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_List)
    public ResponseEntity<?> listAllWeights() {
        try {
            return ResponseEntity.ok(weightService.listAll());
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Save)
    public ResponseEntity<?> saveWeight(@RequestBody WeightRequest request) {
        try {
            return ResponseEntity.ok(weightService.save(request));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(WeightController_Babies)
    public ResponseEntity<?> getBabyWeights(@PathVariable Integer babyId) {
        try {
            return ResponseEntity.ok(weightService.getBabyWeights(babyId));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(WeightController_Scales)
    public ResponseEntity<?> getScaleWeights(@PathVariable Integer scaleId) {
        try {
            return ResponseEntity.ok(weightService.getScaleWeights(scaleId));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(WeightController_MeasureNow)
    public ResponseEntity<?> measureWeightRightNow(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(weightService.MeasureWeightRightNowViaMqtt(id));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }
}
