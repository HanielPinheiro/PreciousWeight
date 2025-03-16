package precious_weight.controllers;

import precious_weight.models.BabyModel;
import precious_weight.services.BabyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/pacientes")
public class BabyController {

    @Autowired
    private BabyService pacienteService;

    @GetMapping
    public List<BabyModel> listarTodos() {
        return pacienteService.listarTodos();
    }

    @GetMapping("/{id}")
    public ResponseEntity<BabyModel> buscarPorId(@PathVariable Integer id) {
        Optional<BabyModel> paciente = pacienteService.buscarPorId(id);
        return paciente.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping
    public BabyModel salvar(@RequestBody BabyModel babyModel) {
        return pacienteService.salvar(babyModel, null);
    }

    @PutMapping("/{id}") 
    public ResponseEntity<BabyModel> atualizarPaciente(@PathVariable Integer id, @RequestBody PacienteRequest request) {
        Optional<BabyModel> pacienteOptional = pacienteService.buscarPorId(id);
        if (pacienteOptional.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        BabyModel babyModel = pacienteOptional.get();
        babyModel.setHashPaciente(request.getHashPaciente());

        BabyModel babyModelAtualizado = pacienteService.salvar(babyModel, request.getIdBalancaNova());
        return ResponseEntity.ok(babyModelAtualizado);
    }

    public static class PacienteRequest {
        private String hashPaciente;
        private Integer idBalancaNova;

        public String getHashPaciente() {
            return hashPaciente;
        }

        public void setHashPaciente(String hashPaciente) {
            this.hashPaciente = hashPaciente;
        }

        public Integer getIdBalancaNova() {
            return idBalancaNova;
        }

        public void setIdBalancaNova(Integer idBalancaNova) {
            this.idBalancaNova = idBalancaNova;
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable Integer id) {
        pacienteService.deletar(id);
        return ResponseEntity.noContent().build();
    }
}
