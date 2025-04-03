package precious_weight.services;

import precious_weight.models.BabyModel;
import precious_weight.models.BabyLogModel;
import precious_weight.interfaces.iBaby;
import precious_weight.interfaces.iScale;
import precious_weight.interfaces.iBabyLog;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class BabyService {

    @Autowired
    private iBaby iBaby;

    @Autowired
    private iBabyLog iBabyLog;

    @Autowired
    private iScale iScale;

    public List<BabyModel> listAll() {
        return iBaby.findAll();
    }

    public Optional<BabyModel> searchById(Integer id) {
        return iBaby.findById(id);
    }

    public BabyModel save(BabyModel babyModel, Integer newScaleId) {
        if (babyModel.getBabyId() != null) {
            Optional<BabyModel> optionalBaby = iBaby.findById(babyModel.getBabyId());
            if (optionalBaby.isPresent()) {
                Integer lastScaleId = searchLastScaleFrom(babyModel.getBabyId());
                if (newScaleId != null && !newScaleId.equals(lastScaleId)) setBabyLog(babyModel.getBabyId(), lastScaleId, newScaleId);
            }
        }
        return iBaby.save(babyModel);
    }

    private Integer searchLastScaleFrom(Integer babyId) {
        return iBabyLog.findById(babyId).map(BabyLogModel::getNewScaleId).orElse(null);
    }

    private void setBabyLog(Integer babyId, Integer lastScaleId, Integer newScaleId) {
        BabyLogModel log = new BabyLogModel();
        log.setLogDate(LocalDateTime.now());
        log.setBabyId(babyId);
        log.setScaleId(lastScaleId);
        log.setNewScaleId(newScaleId);
        iBabyLog.save(log);
    }

    public void delete(Integer id) {
        iBaby.deleteById(id);
    }
}
