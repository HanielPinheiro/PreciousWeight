package precious_weight.app.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.PathVariable;

import precious_weight.app.interfaces.iWeight;
import precious_weight.app.models.WeightModel;
import precious_weight.app.models.request.WeightRequest;

import java.util.List;
import java.util.stream.Collectors;
import java.time.LocalDateTime;

@Service
public class WeightService {
    @Autowired
    private iWeight iWeight;

    @Autowired
    private ScaleService scaleService;

 @Autowired
    private MqttPublisherService mqttPublisherService;

    public List<WeightModel> listAll() {
        return iWeight.findAll();
    }

    public WeightModel save(WeightRequest request) {
        WeightModel weightModel = new WeightModel();
        weightModel.setWeightDate(LocalDateTime.now());
        weightModel.setWeightValue(request.getWeightValue());
        weightModel.setScaleId(request.getScaleId());
        weightModel.setBabyId(request.getBabyId());
        return iWeight.save(weightModel);
    }

    public List<WeightModel> getBabyWeights(@PathVariable Integer babyId) {
        List<WeightModel> weights = iWeight.findAll();
        return weights.stream().filter(p -> p.getBabyId().equals(babyId)).collect(Collectors.toList());
    }

    public List<WeightModel> getScaleWeights(@PathVariable Integer scaleId) {
        List<WeightModel> weights = iWeight.findAll();
        return weights.stream().filter(p -> p.getScaleId().equals(scaleId)).toList();
    }

    public void saveWeightFromScale(String scaleHash, String weight){
        var scale = scaleService.GetScaleFromHash(scaleHash);
        Integer scaleId = scale.getScaleId();
        Integer babyId  = scaleService.GetBabyIdByScaleId(scaleId);

        var w = new WeightRequest();
        w.setBabyId(babyId);
        w.setScaleId(scaleId);
        w.setWeightValue(Double.parseDouble(weight));

        save(w);
    }

    public WeightModel MeasureWeightRightNowViaMqtt(Integer id){
        var mac = scaleService.GetMacFromScaleId(id);
        //Envio [MEA]
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_MEASURE);

        //aqui deveria aguardar alguns instantes ate mqtt enviar peso de volta, rotina do subscriber rodar e saveWeightFromScale adicionar weight no db
        //então deveria pegar lista de pesos (getScaleWeights) e retornar o ultimo
    }
    
}
