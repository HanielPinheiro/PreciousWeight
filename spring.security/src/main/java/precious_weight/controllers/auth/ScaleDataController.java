package precious_weight.controllers.auth;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import precious_weight.auth.models.ScaleDataModel;
import precious_weight.auth.models.request.ScaleDataRequest;
import precious_weight.auth.models.response.ScaleDataResponse;
import precious_weight.auth.services.ProFuturo__QrCodeService;
import precious_weight.auth.services.ScaleDataService;

import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import static precious_weight.config.system.ApiConstants.*;

@RestController
@RequestMapping(ScaleDataController)
public class ScaleDataController {
    @Autowired
    private ScaleDataService scaleDataService;

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Search)
    public ResponseEntity<?> getById(@PathVariable UUID id) {
        try {
            ScaleDataModel data = scaleDataService.GetScaleFromId(id);
            if (data == null) return ResponseEntity.badRequest().build();
            return GetAnswer(data);
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Search)
    public ResponseEntity<?> getQrCodeById(@PathVariable UUID id) {
        try {
            byte[] pngData = scaleDataService.GetQrCodeFromId(id);
            return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG).body(pngData);
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PostMapping(Controller_List)
    @PreAuthorize("hasAuthority('SCOPE_ADMIN')")
    public ResponseEntity<?> listScaleData() throws Exception {
        return ResponseEntity.ok(scaleDataService.GetScales().stream().map(ScaleDataResponse::new).collect(Collectors.toList()));
    }

    @PostMapping(Controller_New)
    @PreAuthorize("hasAuthority('SCOPE_ADMIN')")
    public ResponseEntity<?> newScaleData(@RequestBody ScaleDataRequest request) {
        boolean exist = scaleDataService.GetScaleFromMac(request.getMac()) != null;
        if(exist) return ResponseEntity.badRequest().body(Map.of("error", "This mac address already was registered."));
        return GetAnswer(scaleDataService.NewScaleData(request));
    }

    @PostMapping(Controller_Update)
    @PreAuthorize("hasAuthority('SCOPE_ADMIN')")
    public ResponseEntity<?> updateScaleData(@RequestBody ScaleDataRequest request) {
        boolean exist = scaleDataService.GetScaleFromId(request.getId()) != null;
        if(!exist) return ResponseEntity.badRequest().body(Map.of("error", "Scale Data not found."));

        exist = scaleDataService.GetScaleFromMac(request.getMac()) != null;
        if(exist) return ResponseEntity.badRequest().body(Map.of("error", "This mac address already was registered."));

        return GetAnswer(scaleDataService.UpdateScaleData(request));
    }

    private ResponseEntity<?> GetAnswer(ScaleDataModel data) {
        var answer = new ScaleDataResponse(data);
        if (data.getQrCode() != null) answer.setQrCode(data.getQrCode());
        return ResponseEntity.ok(data);
    }

}
