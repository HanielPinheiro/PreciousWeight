package precious_weight.services;

import precious_weight.models.BabyModel;
import precious_weight.models.ScaleModel;
import precious_weight.models.BabyLogModel;
import precious_weight.interfaces.iBaby;
import precious_weight.interfaces.iScale;
import precious_weight.interfaces.iBabyLog;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
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

    public List<BabyModel> listarTodos() {
        return iBaby.findAll();
    }

    public Optional<BabyModel> buscarPorId(Integer id) {
        return iBaby.findById(id);
    }

    public BabyModel salvar(BabyModel babyModel, Integer idBalancaNova) {
        
        if (babyModel.getIdPaciente() != null) {
            Optional<BabyModel> pacienteExistente = iBaby.findById(babyModel.getIdPaciente());
            if (pacienteExistente.isPresent()) {
                Integer idBalancaAnterior = buscarUltimaBalancaDoPaciente(babyModel.getIdPaciente());
                
                if (idBalancaNova != null && !idBalancaNova.equals(idBalancaAnterior)) {
                    registrarLogPaciente(babyModel.getIdPaciente(), idBalancaAnterior, idBalancaNova);
                }
            }
        }
        
        return iBaby.save(babyModel);
    }

    private Integer buscarUltimaBalancaDoPaciente(Integer idPaciente) {
        return iBabyLog.findTopByPacienteIdPacienteOrderByDataLogDesc(idPaciente)
                .map(BabyLogModel::getNewScaleId)
                .orElse(null);
    }

    private void registrarLogPaciente(Integer idPaciente, Integer idBalancaAnterior, Integer idBalancaNova) {
        BabyLogModel log = new BabyLogModel();
        log.setDataLog(java.time.LocalDateTime.now());

        
        BabyModel babyModel = iBaby.findById(idPaciente)
                .orElseThrow(() -> new RuntimeException("Paciente não encontrado"));
        log.setPaciente(babyModel);

        
        if (idBalancaAnterior != null && idBalancaAnterior > 0) {
            Optional<ScaleModel> optBalanca = iScale.findById(idBalancaAnterior);
            if (optBalanca.isPresent()) {
                log.setBalanca(optBalanca.get());
            } else {
                
                System.err.println("Aviso: Balança com ID " + idBalancaAnterior + " não encontrada. Salvando log sem balança.");
                log.setBalanca(null);
            }
        } else {
            log.setBalanca(null);
        }

        log.setNewScaleId(idBalancaNova);

        iBabyLog.save(log);
    }

    public void deletar(Integer id) {
        iBaby.deleteById(id);
    }
}
