package precious_weight.services;

import precious_weight.models.BabyModel;
import precious_weight.models.ScaleModel;

import precious_weight.interfaces.iBaby;
import precious_weight.interfaces.iScale;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

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

    public Optional<BabyModel> searchById(Integer id) {
        return iBaby.findById(id);
    }

    public BabyModel save(BabyModel babyModel) {
        return iBaby.save(babyModel);
    }

}
