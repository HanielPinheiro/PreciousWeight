package precious_weight.controllers;

import static precious_weight.config.constants.*;

import org.springframework.http.ResponseEntity;
import precious_weight.models.WeightModel;
import precious_weight.requests.WeightRequest;
import precious_weight.services.WeightService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping(WeightControllerName)
public class WeightController {

    @Autowired
    WeightService weightService;

    @PostMapping(ControllerName_List)
    public ResponseEntity<?> listAll() {
        try {
            return ResponseEntity.ok(weightService.listAll());
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PostMapping(ControllerName_Save)
    public ResponseEntity<?> save(@RequestBody WeightRequest request) {
        try {
            return ResponseEntity.ok(weightService.save(request));
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PostMapping(WeightControllerName_Babies)
    public ResponseEntity<?> getBabyWeights(@PathVariable Integer babyId) {
        try {
            return ResponseEntity.ok(weightService.getBabyWeights(babyId));
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PostMapping(WeightControllerName_Scales)
    public ResponseEntity<?> getScaleWeights(@PathVariable Integer scaleId) {
        try {
            return ResponseEntity.ok(weightService.getScaleWeights(scaleId));
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }


}
