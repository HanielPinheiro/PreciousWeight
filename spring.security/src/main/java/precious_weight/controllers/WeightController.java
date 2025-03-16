package precious_weight.controllers;

import precious_weight.models.WeightModel;
import precious_weight.services.WeightService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@RestController
@RequestMapping("/pesos")
public class WeightController {

    @Autowired
    private WeightService weightService;

    @GetMapping
    public List<WeightModel> listarTodos() {
        return weightService.listarTodos();
    }

    @PostMapping
    public WeightModel salvar(@RequestBody PesoRequest request) {
        WeightModel weightModel = new WeightModel();

        // Converter a String "dataPeso" para LocalDateTime
        DateTimeFormatter formatter = DateTimeFormatter.ISO_DATE_TIME;
        LocalDateTime dataPesoFormatada = LocalDateTime.parse(request.getDataPeso(), formatter);

        weightModel.setDataPeso(dataPesoFormatada);
        weightModel.setPeso(request.getPeso());

        return weightService.salvar(weightModel, request.getIdBalanca(), request.getIdPaciente());
    }

    public static class PesoRequest {
        private String dataPeso;
        private Integer idBalanca;
        private Integer idPaciente;
        private Integer peso;

        public String getDataPeso() {
            return dataPeso;
        }

        public void setDataPeso(String dataPeso) {
            this.dataPeso = dataPeso;
        }

        public Integer getIdBalanca() {
            return idBalanca;
        }

        public void setIdBalanca(Integer idBalanca) {
            this.idBalanca = idBalanca;
        }

        public Integer getIdPaciente() {
            return idPaciente;
        }

        public void setIdPaciente(Integer idPaciente) {
            this.idPaciente = idPaciente;
        }

        public Integer getPeso() {
            return peso;
        }

        public void setPeso(Integer peso) {
            this.peso = peso;
        }
    }
}
