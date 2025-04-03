package precious_weight.controllers;

import org.springframework.security.access.prepost.PreAuthorize;
import precious_weight.interfaces.iBabyLog;
import precious_weight.models.BabyLogModel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import static precious_weight.config.constants.BabyLogsControllerName;
import static precious_weight.config.constants.ControllerName_List;
import static precious_weight.config.constants.ControllerName_Save;

@RestController
@RequestMapping(BabyLogsControllerName)
public class BabyLogController {
    @Autowired
    private iBabyLog iBabyLog;

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_List)
    public List<BabyLogModel> listAll() {
        return iBabyLog.findAll();
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ControllerName_Save)
    public BabyLogModel save(@RequestBody BabyLogModel babyLogModel) {
        return iBabyLog.save(babyLogModel);
    }
}
