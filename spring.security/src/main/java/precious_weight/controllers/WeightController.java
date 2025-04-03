package precious_weight.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import precious_weight.interfaces.iBaby;
import precious_weight.interfaces.iScale;
import precious_weight.interfaces.iWeight;
import precious_weight.models.BabyModel;
import precious_weight.models.ScaleLogModel;
import precious_weight.models.ScaleModel;
import precious_weight.models.WeightModel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

import static precious_weight.config.constants.WeightControllerName;
import static precious_weight.config.constants.ControllerName_List;
import static precious_weight.config.constants.ControllerName_Save;

@RestController
@RequestMapping(WeightControllerName)
public class WeightController {

    @Autowired
    private iWeight iWeight;

    @Autowired
    private iScale iScale;

    @Autowired
    private iBaby iBaby;

    @PostMapping(ControllerName_List)
    public List<WeightModel> listAll() {
        return iWeight.findAll();
    }

    @PostMapping(ControllerName_Save)
    public WeightModel save(@RequestBody WeightRequestModel request) {
        WeightModel weightModel = new WeightModel();
        weightModel.setWeightDate(LocalDateTime.now());
        weightModel.setWeightValue(request.getWeightValue());
        weightModel.setScaleId(request.getScaleId());
        weightModel.setBabyId(request.getBabyId());
        return iWeight.save(weightModel);
    }

    public static class WeightRequestModel {
        private String weightDate;
        private Integer scaleId;
        private Integer babyId;
        private Integer weightValue;

        public String getWeightDate() {
            return weightDate;
        }
        public void setWeightDate(String weightDate) {
            this.weightDate = weightDate;
        }

        public Integer getScaleId() {
            return scaleId;
        }
        public void setScaleId(Integer scaleId) {
            this.scaleId = scaleId;
        }

        public Integer getBabyId() {
            return babyId;
        }
        public void setBabyId(Integer babyId) {
            this.babyId = babyId;
        }

        public Integer getWeightValue() {
            return weightValue;
        }
        public void setWeightValue(Integer weightValue) {
            this.weightValue = weightValue;
        }
    }
}
