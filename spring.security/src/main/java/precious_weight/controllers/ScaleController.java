package precious_weight.controllers;

import org.springframework.security.access.prepost.PreAuthorize;

import precious_weight.interfaces.iBaby;
import precious_weight.models.BabyModel;
import precious_weight.models.ScaleModel;
import precious_weight.interfaces.iScale;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

import static precious_weight.config.constants.*;

@RestController
@RequestMapping(ScaleControllerName)
public class ScaleController {
    @Autowired
    private iScale iScale;
    @Autowired
    private iBaby iBaby;

    /**
     * ====================================================================================
     * CREATE / READ
     * ===================================================================================
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_List)
    public List<ScaleModel> listAll() {
        return GetScales();
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Search)
    public ResponseEntity<ScaleModel> searchById(@PathVariable Integer id) {
        ScaleModel scaleWithBabyData = GetWithBabyById(id);
        if (scaleWithBabyData == null) return ResponseEntity.badRequest().build();
        return ResponseEntity.ok(scaleWithBabyData);
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleControllerName_Save)
    public ResponseEntity<ScaleModel> save(@PathVariable String scaleHash) {
        try {
            ScaleModel newScale = new ScaleModel();
            newScale.setScaleHash(scaleHash);
            newScale.setScaleState(0);
            return ResponseEntity.ok(iScale.save(newScale));
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * ====================================================================================
     * UPDATE  SCALE / HASH
     * ===================================================================================
     */

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Update)
    public ResponseEntity<ScaleModel> updateHash(@PathVariable Integer id, @RequestBody ScaleModel model) {
        try {
            if (iScale.findById(id).isEmpty()) return ResponseEntity.badRequest().build();
            ScaleModel scale = iScale.getReferenceById(id);
            scale.setScaleHash(model.getScaleHash());
            iScale.save(scale);
            return ResponseEntity.ok(GetWithBabyById(id));
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * ====================================================================================
     * UPDATE STATE -> ENABLE / DISABLE
     * ===================================================================================
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Enable)
    public ResponseEntity<ScaleModel> enableScale(@PathVariable Integer id) {
        try {
            return enableOrDisable(id, true);
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Disable)
    public ResponseEntity<ScaleModel> disableScale(@PathVariable Integer id) {
        try {
            return enableOrDisable(id, false);
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    private ResponseEntity<ScaleModel> enableOrDisable(Integer id, boolean enabled) {
        var scaleWithBabyData = GetWithBabyById(id).getAssignedBaby();
        if (scaleWithBabyData != null) return ResponseEntity.badRequest().build();

        if (iScale.findById(id).isEmpty()) return ResponseEntity.badRequest().build();
        int value = enabled ? ScaleStates.operant.value : ScaleStates.nonOperant.value;
        ScaleModel scale = iScale.getReferenceById(id);
        scale.setScaleState(value);
        iScale.save(scale);
        return ResponseEntity.ok(GetWithBabyById(id));
    }

    /**
     * ====================================================================================
     * UPDATE BABY -> SET / UNSET
     * ===================================================================================
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleControllerName_SetBaby)
    public ResponseEntity<ScaleModel> setBaby(@RequestBody ScaleModel model) {
        try {
            return setOrUnset(model, true);
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleControllerName_UnsetBaby)
    public ResponseEntity<ScaleModel> unsetBaby(@RequestBody ScaleModel model) {
        try {
            return setOrUnset(model, false);
        } catch (Exception ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    private ResponseEntity<ScaleModel> setOrUnset(ScaleModel model, boolean set) {
        var scaleId = model.getScaleId();
        var babyId = model.getBabyId();

        if (iScale.findById(scaleId).isEmpty()) return ResponseEntity.badRequest().build();

        if (set) {
            var scaleHasBaby = GetWithBabyById(scaleId).getAssignedBaby();
            if (scaleHasBaby != null) return ResponseEntity.badRequest().build();

            if (iBaby.findById(babyId).isEmpty()) return ResponseEntity.badRequest().build();
            if (BabyHasScale(babyId)) return ResponseEntity.badRequest().build();

            ScaleModel scale = iScale.getReferenceById(scaleId);
            if (scale.getScaleState() == ScaleStates.nonOperant.value)
                return ResponseEntity.badRequest().build();

            scale.setBabyId(babyId);
            iScale.save(scale);
            return ResponseEntity.ok(GetWithBabyById(scaleId));
        } else {
            ScaleModel scaleWithBabyData = GetWithBabyById(model.getScaleId());
            scaleWithBabyData.setBabyId(null);
            return ResponseEntity.ok(iScale.save(scaleWithBabyData));
        }
    }

    private ScaleModel GetWithBabyById(Integer scaleId) {
        return GetScales().stream().filter(s -> s.getScaleId().equals(scaleId)).
                findFirst().orElse(null);
    }

    private List<ScaleModel> GetScales() {
        List<ScaleModel> scales = iScale.findAll();

        // Get all babies for scales that have babyId assigned
        Set<Integer> babyIds = scales.stream()
                .map(ScaleModel::getBabyId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        Map<Integer, BabyModel> babyMap = iBaby.findAllByBabyIdIn(babyIds).stream()
                .collect(Collectors.toMap(BabyModel::getBabyId, Function.identity()));

        // Enhance each scale with baby information
        scales.forEach(scale -> {
            if (scale.getBabyId() != null) scale.setAssignedBaby(babyMap.get(scale.getBabyId()));
        });

        return scales;
    }

    private Boolean BabyHasScale(Integer babyId) {
        List<ScaleModel> scales = iScale.findAll();

        // Get all babies for scales that have babyId assigned
        Set<Integer> babyIds = scales.stream()
                .map(ScaleModel::getBabyId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        Integer find = babyIds.stream().filter(s -> s.equals(babyId))
                .findFirst().orElse(null);
        return find != null;
    }

    public enum ScaleStates {
        nonOperant(0), operant(1);
        public final int value;

        ScaleStates(int _value) {
            value = _value;
        }
    }
}


