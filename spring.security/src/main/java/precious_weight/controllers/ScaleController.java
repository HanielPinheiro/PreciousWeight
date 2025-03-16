package precious_weight.controllers;

import org.springframework.security.access.prepost.PreAuthorize;
import precious_weight.models.ScaleModel;
import precious_weight.interfaces.iScale;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import precious_weight.services.ScaleLogService;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/scales")
public class ScaleController {

    private ScaleLogService scaleLogService;

    @Autowired
    private iScale iScale;

    @PreAuthorize("isAuthenticated()")
    @GetMapping
    public List<ScaleModel> listAll() {
        return iScale.findAll();
    }

    @PostMapping("/search/{id}")
    public ResponseEntity<ScaleModel> searchById(@PathVariable Integer id) {
        Optional<ScaleModel> scale = iScale.findById(id);
        return scale.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping("/save")
    public ScaleModel save(@RequestBody ScaleModel scaleModel) {
        if (scaleModel.getScaleId() == null) {
            return iScale.save(scaleModel);
        }
        Optional<ScaleModel> balancaExistente = iScale.findById(scaleModel.getScaleId());
        if (balancaExistente.isPresent()) {
            Integer estadoAnterior = balancaExistente.get().getScaleState();
            Integer novoEstado = scaleModel.getScaleState();
            if (!estadoAnterior.equals(novoEstado)) {

                scaleLogService.registrarLogBalanca(scaleModel.getScaleId(), estadoAnterior, novoEstado);
            }
        }

        return iScale.save(scaleModel);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        iScale.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
