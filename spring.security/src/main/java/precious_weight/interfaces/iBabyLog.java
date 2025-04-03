package precious_weight.interfaces;

import precious_weight.models.BabyLogModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface iBabyLog extends JpaRepository<BabyLogModel, Integer> {
}
