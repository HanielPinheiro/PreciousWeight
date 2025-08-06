package precious_weight.controllers;

import static precious_weight.config.system.GlobalConstants.*;
import precious_weight.app.models.ScaleModel;
import precious_weight.app.services.ScaleService;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping(ScaleControllerName)
public class ScaleController {

    @Autowired
    private ScaleService scaleService;

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_List)
    public ResponseEntity<?> listAll() {
        try {
            return ResponseEntity.ok(scaleService.GetScales());
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Search)
    public ResponseEntity<?> searchById(@PathVariable Integer id) {
        try {
            ScaleModel data = scaleService.GetScaleFromId(id);
            return data != null ? ResponseEntity.ok(data) : ResponseEntity.badRequest().build();
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleControllerName_Save)
    public ResponseEntity<?> save(@PathVariable String scaleHash) {
        try {
            return  ResponseEntity.ok(scaleService.save(scaleHash));
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Update)
    public ResponseEntity<?> updateHash(@PathVariable Integer id, @RequestBody ScaleModel model) {
        try {
            return ResponseEntity.ok(scaleService.updateHash(id, model));
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Enable)
    public ResponseEntity<?> enableScale(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(scaleService.enableOrDisable(id, true));
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Disable)
    public ResponseEntity<?> disableScale(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(scaleService.enableOrDisable(id, false));
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleControllerName_SetBaby)
    public ResponseEntity<?> setBaby(@RequestBody ScaleModel model) {
        try {
            return ResponseEntity.ok(scaleService.setOrUnset(model, true));
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleControllerName_UnsetBaby)
    public ResponseEntity<?> unsetBaby(@RequestBody ScaleModel model) {
        try {
            return ResponseEntity.ok(scaleService.setOrUnset(model, false));
        } catch (Exception ex) {
            Map<String, String> error = new HashMap<String, String>() {{
                put("error", ex.getMessage());
            }};
            return ResponseEntity.badRequest().body(error);
        }
    }
}


