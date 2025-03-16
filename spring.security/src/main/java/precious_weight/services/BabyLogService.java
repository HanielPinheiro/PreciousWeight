package precious_weight.services;

import precious_weight.models.BabyModel;
import precious_weight.models.BabyLogModel;
import precious_weight.models.ScaleModel;
import precious_weight.interfaces.iBabyLog;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class BabyLogService {

    @Autowired
    private iBabyLog iBabyLog;

    public List<BabyLogModel> listarTodos() {
        return iBabyLog.findAll();
    }

    public BabyLogModel salvar(BabyLogModel babyLogModel) {
        return iBabyLog.save(babyLogModel);
    }

    public void registrarLogPaciente(Integer idPaciente, Integer idBalancaAnterior, Integer idBalancaNova) {
        BabyLogModel log = new BabyLogModel();
        log.setDataLog(LocalDateTime.now());
        log.setPaciente(new BabyModel());
        log.getPaciente().setIdPaciente(idPaciente);
        log.setBalanca(new ScaleModel());
        log.getBalanca().setScaleId(idBalancaAnterior);
        log.setNewScaleId(idBalancaNova);

        iBabyLog.save(log);
    }
}
