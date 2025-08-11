package precious_weight.app.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import precious_weight.app.interfaces.iBaby;
import precious_weight.app.interfaces.iScale;
import precious_weight.app.models.ScaleModel;
import precious_weight.app.models.BabyModel;
import precious_weight.auth.services.MqttPublisherService;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class ScaleService {
    public enum ScaleStates {
        nonOperant(0), operant(1);
        public final int value;
        ScaleStates(int _value) {
            value = _value;
        }
    }

    @Autowired
    private iScale iScale;

    @Autowired
    private iBaby iBaby;

    @Autowired
    private MqttPublisherService mqttPublisherService;

    public List<ScaleModel> GetScales() {
        List<ScaleModel> scales = iScale.findAll();

        // Get all babies for scales that have babyId assigned
        Set<Integer> babyIds = scales.stream().map(ScaleModel::getBabyId).filter(Objects::nonNull).collect(Collectors.toSet());

        Map<Integer, BabyModel> babyMap = iBaby.findAllByBabyIdIn(babyIds).stream().collect(Collectors.toMap(BabyModel::getBabyId, Function.identity()));

        // Enhance each scale with baby information
        scales.forEach(scale -> {
            if (scale.getBabyId() != null) scale.setAssignedBaby(babyMap.get(scale.getBabyId()));
        });

        return scales;
    }

    public ScaleModel GetScaleFromId(Integer scaleId) {
        return GetScales().stream().filter(s -> s.getScaleId().equals(scaleId)).findFirst().orElse(null);
    }

    public ScaleModel GetScaleFromHash(String scaleHash) {
        List<ScaleModel> scales = iScale.findAll();
        return scales.stream().filter(s -> s.getScaleHash().equals(scaleHash)).findFirst().orElse(null);
    }

    public Integer GetBabyIdByScaleId(Integer scaleId) {
        return iScale.findById(scaleId).map(ScaleModel::getBabyId).orElse(null);
    }

      public ScaleModel SetScaleToUser(String scaleHash) {
        ScaleModel newScale = new ScaleModel();
        newScale.setScaleHash(scaleHash);
        newScale.setScaleState(0);
        return iScale.save(newScale);
    }

    public ScaleModel UpdateHash(Integer id, ScaleModel model) throws Exception {
        if (iScale.findById(id).isEmpty()) throw new Exception("iScale is empty when try to update hash");
        ScaleModel scale = iScale.getReferenceById(id);
        scale.setScaleHash(model.getScaleHash());
        iScale.save(scale);
        return GetScaleFromId(id);
    }


    public ScaleModel EnableOrDisable(Integer id, boolean enabled) throws Exception {
        var scaleWithBabyData = GetScaleFromId(id).getAssignedBaby();
        if (scaleWithBabyData != null) throw new Exception("iScale is empty when try to enable Or disable");

        if (iScale.findById(id).isEmpty()) throw new Exception("iScale is empty when try to enable or disable");
        int value = enabled ? ScaleStates.operant.value : ScaleStates.nonOperant.value;
        ScaleModel scale = iScale.getReferenceById(id);
        scale.setScaleState(value);
        iScale.save(scale);
        return GetScaleFromId(id);
    }

    public ScaleModel SetOrUnset(ScaleModel model, boolean set) throws Exception {
        var scaleId = model.getScaleId();
        var babyId = model.getBabyId();

        if (iScale.findById(scaleId).isEmpty()) throw new Exception("iScale is empty when try to set or unset");

        if (set) {
            var scaleHasBaby = GetScaleFromId(scaleId).getAssignedBaby();
            if (scaleHasBaby != null) throw new Exception("scale already has a baby when try to set or unset");

            if (iBaby.findById(babyId).isEmpty()) throw new Exception("baby not found when try to set or unset");
            if (BabyHasScale(babyId)) throw new Exception("baby already has a scale when try to set or unset");

            ScaleModel scale = iScale.getReferenceById(scaleId);
            if (scale.getScaleState() == ScaleStates.nonOperant.value) throw new Exception("iScale is not operant when try to set or unset");

            scale.setBabyId(babyId);
            iScale.save(scale);

            /* enviar dado para balanca definindo horário da pesagem desse bebe */
            mqttPublisherService.sendCriticalCommand(scale.getScaleHash(), iBaby.findById(babyId).get().getBabyWeightHour());

            return GetScaleFromId(scaleId);
        } else {
            ScaleModel scaleWithBabyData = GetScaleFromId(model.getScaleId());
            scaleWithBabyData.setBabyId(null);
            return iScale.save(scaleWithBabyData);
        }
    }


    private Boolean BabyHasScale(Integer babyId) {
        List<ScaleModel> scales = iScale.findAll();

        // Get all babies for scales that have babyId assigned
        Set<Integer> babyIds = scales.stream().map(ScaleModel::getBabyId).filter(Objects::nonNull).collect(Collectors.toSet());

        Integer find = babyIds.stream().filter(s -> s.equals(babyId)).findFirst().orElse(null);

        return find != null;
    }

}
