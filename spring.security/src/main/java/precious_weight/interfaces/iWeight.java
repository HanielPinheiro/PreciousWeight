package precious_weight.interfaces;

import precious_weight.models.WeightModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface iWeight extends JpaRepository<WeightModel, Integer> {
}
