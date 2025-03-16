package precious_weight.interfaces;

import precious_weight.models.BabyModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface iBaby extends JpaRepository<BabyModel, Integer> {
}
