package precious_weight.interfaces;

import precious_weight.models.ScaleLogModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface iScaleLog extends JpaRepository<ScaleLogModel, Integer> {
}
