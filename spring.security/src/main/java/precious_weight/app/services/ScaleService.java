package precious_weight.app.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import precious_weight.app.interfaces.iBaby;
import precious_weight.app.interfaces.iScale;
import precious_weight.app.models.ScaleModel;
import precious_weight.app.models.BabyModel;
import precious_weight.app.models.request.ScaleRequest;
import precious_weight.auth.services.MqttPublisherService;
import precious_weight.auth.services.ScaleDataService;

import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

import static precious_weight.config.system.MqttConstants.*;

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

    @Autowired
    private ScaleDataService scaleDataService;

    public List<ScaleModel> GetScales() {
        return iScale.findAll();
    }

    public ScaleModel GetScaleFromId(Integer scaleId) {
        return GetScales().stream().filter(s -> s.getScaleId().equals(scaleId)).findFirst().orElse(null);
    }

    public ScaleModel GetScaleFromHash(String scaleHash) {
        List<ScaleModel> scales = iScale.findAll();
        return scales.stream().filter(s -> s.getScaleHash().equals(scaleHash)).findFirst().orElse(null);
    }

    public List<ScaleModel> GetScalesWithBaby() {
        return iScale.findAll().stream().filter(p->p.getAssignedBaby() != null).toList();
    }

    public Integer GetBabyIdByScaleId(Integer scaleId) {
        return iScale.findById(scaleId).get().getAssignedBaby().getBabyId();

    }

    public ScaleModel SetScaleToUser(UUID id) throws Exception {
        if (scaleDataService.GetScaleFromId(id) == null) throw new Exception("Invalid ID!");
        if(GetScaleFromHash(id.toString()) != null) throw new Exception("Scale already inserted");

        ScaleModel newScale = new ScaleModel();
        newScale.setScaleHash(id.toString());
        newScale.setScaleState(0);
        return iScale.save(newScale);
    }

    public ScaleModel EnableOrDisable(Integer id, boolean enabled) throws Exception {
        ScaleModel scale = GetScaleFromId(id);
        if (scale == null) throw new Exception("Scale not found");
        if (scale.getAssignedBaby() != null) throw new Exception("Scale has a baby attached to it. Unset the baby first.");

        int value = enabled ? ScaleStates.operant.value : ScaleStates.nonOperant.value;
        scale.setScaleState(value);
        iScale.save(scale);
        return GetScaleFromId(id);
    }

    public String GetMacFromScaleByHash(String scaleHash) throws Exception {
        return scaleDataService.GetScaleMacFromScaleHashId(scaleHash);
    }

    public ScaleModel SetOrUnsetBabyToScale(ScaleRequest scaleRequest, boolean set) throws Exception {
        Integer scaleId = scaleRequest.getScaleId();
        Integer babyId = scaleRequest.getBabyId();

        ScaleModel scale = GetScaleFromId(scaleId);
        if (scale == null) throw new Exception("Scale not found");
        if (set) {
            if (scale.getAssignedBaby() != null) throw new Exception("Scale already has a baby");

            BabyModel baby = iBaby.findById(babyId).orElse(null);
            if (baby == null) throw new Exception("Baby not found!");

            if (BabyHasScale(babyId) != null) throw new Exception("Baby already has a scale");

            if (scale.getScaleState() == ScaleStates.nonOperant.value) throw new Exception("Scale is not operant");
            scale.setAssignedBaby(baby);
            iScale.save(scale);

            String mac = GetMacFromScaleByHash(scale.getScaleHash());
            String babyWeightTime = baby.getBabyWeightTime();
            SendBabyDataToScaleViaMqtt(mac, babyId, babyWeightTime);

            return iScale.findById(scaleId).get();
        } else {
            ScaleModel scaleWithBabyData = GetScaleFromId(scale.getScaleId());
            scaleWithBabyData.setAssignedBaby(null);

            SendClearToScaleViaMqtt(GetMacFromScaleByHash(scaleWithBabyData.getScaleHash()));

            iScale.save(scaleWithBabyData);
            return iScale.findById(scaleId).get();
        }
    }


    private Boolean BabyHasScale(Integer babyId) {
        List<ScaleModel> scales = GetScalesWithBaby(); // Get all babies for scales that have babyId assigned
        if(scales.isEmpty()) return null;
        ScaleModel find = scales.stream().filter(s -> Objects.equals(s.getAssignedBaby().getBabyId(), babyId)).toList().getFirst();
        return find != null;
    }

    private void SendClearToScaleViaMqtt(String mac ){
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_CLEAR);
    }

    private void SendBabyDataToScaleViaMqtt(String mac, Integer babyId, String babyWeightTime) throws Exception {
        //Envio [BAB]ID
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_BABY + babyId.toString());

        //Envio [WEI]time
        if (babyWeightTime== null)  //time = 12:00
            mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_WEIGHT_TIME + DEFAULT_WEIGHT_TIME);

        else { // vários 'times' =>08:00$09:00$10:00...
            String[] weightTimes = babyWeightTime.split("\\$");
            if (weightTimes.length == 0)
                mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_WEIGHT_TIME + babyWeightTime);
            else
                for (String weightTime : weightTimes) mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_WEIGHT_TIME + weightTime);
        }

        //Envio [RUN]
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_RUN);
    }

    public void SendNewWeightTimesToScale(Integer babyId, String babyWeightTime) throws Exception {
        String hash = iBaby.getReferenceById(babyId).getAssignedScale().getScaleHash();
        String mac = GetMacFromScaleByHash(hash);
        SendClearToScaleViaMqtt(mac);
        SendBabyDataToScaleViaMqtt(mac,babyId,babyWeightTime);
    }
}
