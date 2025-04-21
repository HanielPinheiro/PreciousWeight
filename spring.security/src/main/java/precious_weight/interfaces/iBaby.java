package precious_weight.interfaces;

import precious_weight.models.BabyModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import precious_weight.models.ScaleModel;

import java.util.List;
import java.util.Set;

@Repository
public interface iBaby extends JpaRepository<BabyModel, Integer> {
    List<BabyModel> findAllByBabyIdIn(Set<Integer> ids);
}
