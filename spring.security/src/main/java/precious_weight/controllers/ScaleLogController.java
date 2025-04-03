package precious_weight.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.server.ResponseStatusException;
import precious_weight.interfaces.iScaleLog;
import precious_weight.models.ScaleLogModel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import precious_weight.models.ScaleModel;

import java.util.List;

import static precious_weight.config.constants.ScaleLogsControllerName;
import static precious_weight.config.constants.ControllerName_List;
import static precious_weight.config.constants.ControllerName_Save;

@RestController
@RequestMapping(ScaleLogsControllerName)
public class ScaleLogController {

    @Autowired
    private iScaleLog scaleLogRepository;

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_List)
    public List<ScaleLogModel> listAll() { return scaleLogRepository.findAll(); }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Save)
    public ScaleLogModel save(@RequestBody ScaleLogModel scaleLogModel) {
        return scaleLogRepository.save(scaleLogModel);
    }
}
