package precious_weight.controllers;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import precious_weight.app.models.envers.AuditRepository;

import java.util.List;

import static precious_weight.config.system.GlobalConstants.*;

@RestController
@RequestMapping(AuditControllerName)
public class AuditController {

    private final AuditRepository auditRepository;

    public AuditController(AuditRepository auditRepository) {
        this.auditRepository = auditRepository;
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(AuditControllerName_Babies)
    public List<Object[]> getBabyAudit(@PathVariable Integer babyId) {
        return auditRepository.getBabyRevisions(babyId);
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(AuditControllerName_Scales)
    public List<Object[]> getScaleAudit(@PathVariable Integer scaleId) {
        return auditRepository.getScaleRevisions(scaleId);
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(AuditControllerName_Weights)
    public List<Object[]> getWeightAudit(@PathVariable Integer babyId) {
        return auditRepository.getWeightRevisions(babyId);
    }
}