package precious_weight.app.services;

import precious_weight.auth.services.MqttPublisherService;
import precious_weight.controllers.BabyController;
import precious_weight.app.models.BabyModel;
import precious_weight.app.models.ScaleModel;
import precious_weight.app.interfaces.iBaby;
import precious_weight.app.interfaces.iScale;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.sql.Blob;
import javax.sql.rowset.serial.SerialBlob;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class BabyService {
    @Autowired
    private iBaby iBaby;

    @Autowired
    private iScale iScale;

    @Autowired
    private MqttPublisherService mqttPublisherService;

    public List<BabyModel> listAll() {
        List<BabyModel> babies = iBaby.findAll();
        List<ScaleModel> assignedScales = iScale.findByBabyIdIsNotNull();

        Map<Integer, ScaleModel> babyToScaleMap = assignedScales.stream()
                .collect(Collectors.toMap(ScaleModel::getBabyId, Function.identity()));

        babies.forEach(baby -> {
            if (babyToScaleMap.containsKey(baby.getBabyId()))
                baby.setAssignedScale(babyToScaleMap.get(baby.getBabyId()));
        });

        return babies;
    }

    public BabyModel searchById(Integer id) throws Exception {
        Optional<BabyModel> baby = iBaby.findById(id);
        if (baby.isEmpty()) throw new Exception("Error when try to search baby by id");
        return baby.get();
    }

    public BabyModel save(BabyModel babyModel) {
        return iBaby.save(babyModel);
    }

    public void uploadImage(Integer id, MultipartFile file) throws Exception {
        Blob scaleImage = new SerialBlob(file.getBytes());

        BabyModel babyModel = searchById(id);
        babyModel.setBabyImage(scaleImage);
        save(babyModel);
    }

    public BabyModel enableOrDisable(Integer babyId, boolean enabled) throws Exception {
        // Verificar se existe balança vinculada ao bebe
        var babiesWithAndWithoutScales = listAll();
        var baby = babiesWithAndWithoutScales.stream().filter(s -> s.getBabyId().equals(babyId))
                .findFirst().orElse(null);

        // Se sim, retornar erro
        if (baby == null) throw new Exception("Error when try to enable or disable -> baby is null");
        if (baby.getAssignedScale() != null) throw new Exception("Error when try to enable or disable -> baby has scale");

        // Se não, prosseguir com a ação
        var val = enabled ? BabyController.BabyStates.enabled.value : BabyController.BabyStates.disabled.value;
        baby.setBabyState(val);
        return save(baby);
    }

    public BabyModel update(Integer id, BabyModel request) throws Exception {
            BabyModel babyModel = searchById(id);

            if (request.getBabyHospitalId() != null)
                babyModel.setBabyHospitalId(request.getBabyHospitalId());

            if (request.getBabyName() != null)
                babyModel.setBabyName(request.getBabyName());

            if (request.getBabyMotherName() != null)
                babyModel.setBabyMotherName(request.getBabyMotherName());

            if (request.getBabyBirthDate() != null)
                babyModel.setBabyBirthDate(request.getBabyBirthDate());

            if (request.getBabyImageText() != null)
                babyModel.setBabyImageText(request.getBabyImageText());

            if (request.getBabyWeightHour() != null) {
                babyModel.setBabyWeightHour(request.getBabyWeightHour());
                //verifico se bebe tem balança
                var scales = iScale.findByBabyId(babyModel.getBabyId());

                //se tiver, envio novo horário pra balança
                if(!scales.isEmpty()) {
                    /* enviar dado para balanca definindo horário da pesagem desse bebe */
                    mqttPublisherService.sendCriticalCommand(scales.getFirst().getScaleHash(),babyModel.getBabyWeightHour());
                }
            }

            return save(babyModel);
    }
}
