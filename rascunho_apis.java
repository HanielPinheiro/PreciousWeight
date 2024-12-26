import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.web.bind.annotation.*;

import javax.persistence.*;
import java.time.LocalDateTime;
import java.util.List;

@SpringBootApplication
public class BalancaPacienteApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(BalancaPacienteApiApplication.class, args);
    }
}

// Entity Classes
@Entity
class Balanca {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private String hash;
    private Integer estado; // 0: Vaga, 1: Operante, 2: Inoperante

    // Getters and Setters
    // ...
}

@Entity
class Paciente {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private String hash;

    // Getters and Setters
    // ...
}

@Entity
class Peso {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private LocalDateTime data;
    private Integer peso;

    @ManyToOne
    @JoinColumn(name = "balanca_id")
    private Balanca balanca;

    @ManyToOne
    @JoinColumn(name = "paciente_id")
    private Paciente paciente;

    // Getters and Setters
    // ...
}

@Entity
class LogBalanca {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private LocalDateTime data;
    private Integer estadoAnterior;
    private Integer novoEstado;

    @ManyToOne
    @JoinColumn(name = "balanca_id")
    private Balanca balanca;

    // Getters and Setters
    // ...
}

@Entity
class LogPaciente {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private LocalDateTime data;

    @ManyToOne
    @JoinColumn(name = "paciente_id")
    private Paciente paciente;

    @ManyToOne
    @JoinColumn(name = "balanca_anterior_id")
    private Balanca balancaAnterior;

    @ManyToOne
    @JoinColumn(name = "balanca_nova_id")
    private Balanca balancaNova;

    // Getters and Setters
    // ...
}

// Repositories
interface BalancaRepository extends JpaRepository<Balanca, Integer> {}
interface PacienteRepository extends JpaRepository<Paciente, Integer> {}
interface PesoRepository extends JpaRepository<Peso, Integer> {}
interface LogBalancaRepository extends JpaRepository<LogBalanca, Integer> {}
interface LogPacienteRepository extends JpaRepository<LogPaciente, Integer> {}

// Controllers
@RestController
@RequestMapping("/api/balancas")
class BalancaController {
    private final BalancaRepository repository;
    private final LogBalancaRepository logRepository;

    public BalancaController(BalancaRepository repository, LogBalancaRepository logRepository) {
        this.repository = repository;
        this.logRepository = logRepository;
    }

    @GetMapping
    public List<Balanca> getAll() {
        return repository.findAll();
    }

    @PostMapping
    public Balanca create(@RequestBody Balanca balanca) {
        return repository.save(balanca);
    }

    @PutMapping("/{id}/estado")
    public Balanca updateEstado(@PathVariable Integer id, @RequestParam Integer novoEstado) {
        Balanca balanca = repository.findById(id).orElseThrow(() -> new RuntimeException("Balança não encontrada"));
        LogBalanca log = new LogBalanca();
        log.setData(LocalDateTime.now());
        log.setEstadoAnterior(balanca.getEstado());
        log.setNovoEstado(novoEstado);
        log.setBalanca(balanca);
        logRepository.save(log);

        balanca.setEstado(novoEstado);
        return repository.save(balanca);
    }
}

@RestController
@RequestMapping("/api/pacientes")
class PacienteController {
    private final PacienteRepository repository;
    private final LogPacienteRepository logRepository;

    public PacienteController(PacienteRepository repository, LogPacienteRepository logRepository) {
        this.repository = repository;
        this.logRepository = logRepository;
    }

    @GetMapping
    public List<Paciente> getAll() {
        return repository.findAll();
    }

    @PostMapping
    public Paciente create(@RequestBody Paciente paciente) {
        return repository.save(paciente);
    }
}

@RestController
@RequestMapping("/api/pesos")
class PesoController {
    private final PesoRepository repository;

    public PesoController(PesoRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<Peso> getAll() {
        return repository.findAll();
    }

    @PostMapping
    public Peso create(@RequestBody Peso peso) {
        return repository.save(peso);
    }
}
