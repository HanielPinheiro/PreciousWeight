package precious_weight.controllers;

import precious_weight.models.ScaleLogModel;
import precious_weight.services.ScaleLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/log-balancas")
public class ScaleLogController {

    @Autowired
    private ScaleLogService scaleLogService;

    @GetMapping
    public List<ScaleLogModel> listarTodos() {
        return scaleLogService.listarTodos();
    }

    @PostMapping
    public ScaleLogModel salvar(@RequestBody ScaleLogModel scaleLogModel) {
        return scaleLogService.salvar(scaleLogModel);
    }
}
