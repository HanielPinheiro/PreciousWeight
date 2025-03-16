package precious_weight.controllers;

import precious_weight.models.BabyLogModel;
import precious_weight.services.BabyLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/log-pacientes")
public class BabyLogController {

    @Autowired
    private BabyLogService babyLogService;

    @GetMapping
    public List<BabyLogModel> listarTodos() {
        return babyLogService.listarTodos();
    }

    @PostMapping
    public BabyLogModel salvar(@RequestBody BabyLogModel babyLogModel) {
        return babyLogService.salvar(babyLogModel);
    }
}
