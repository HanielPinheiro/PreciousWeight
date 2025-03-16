package precious_weight.services;

import precious_weight.models.ScaleModel;
import precious_weight.models.ScaleLogModel;
import precious_weight.interfaces.iScaleLog;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ScaleLogService {

    @Autowired
    private iScaleLog patientLogRepository;

    public List<ScaleLogModel> listarTodos() {
        return patientLogRepository.findAll();
    }

    public ScaleLogModel salvar(ScaleLogModel scaleLogModel) {
        return patientLogRepository.save(scaleLogModel);
    }

    public void registrarLogBalanca(Integer idBalanca, Integer estadoAnterior, Integer novoEstado) {
        ScaleLogModel log = new ScaleLogModel();
        log.setDataLog(LocalDateTime.now());

        
        ScaleModel scaleModel = new ScaleModel();
        scaleModel.setScaleId(idBalanca);
        log.setBalanca(scaleModel);

        log.setEstadoBalanca(estadoAnterior);
        log.setNovoEstadoBalanca(novoEstado);
        
        patientLogRepository.save(log);
    }
}
