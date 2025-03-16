package precious_weight.services;

import precious_weight.models.ScaleModel;
import precious_weight.models.BabyModel;
import precious_weight.models.WeightModel;
import precious_weight.interfaces.iScale;
import precious_weight.interfaces.iBaby;
import precious_weight.interfaces.iWeight;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class WeightService {

    @Autowired
    private iWeight iWeight;

    @Autowired
    private iScale iScale;

    @Autowired
    private iBaby iBaby;

    public List<WeightModel> listarTodos() {
        return iWeight.findAll();
    }

    public WeightModel salvar(WeightModel weightModel, Integer idBalanca, Integer idPaciente) {
        
        Optional<ScaleModel> balancaOpt = iScale.findById(idBalanca);
        if (balancaOpt.isEmpty()) {
            throw new RuntimeException("Balança não encontrada!");
        }

        
        Optional<BabyModel> pacienteOpt = iBaby.findById(idPaciente);
        if (pacienteOpt.isEmpty()) {
            throw new RuntimeException("Paciente não encontrado!");
        }

        
        weightModel.setBalanca(balancaOpt.get());
        weightModel.setPaciente(pacienteOpt.get());

        return iWeight.save(weightModel);
    }
}
