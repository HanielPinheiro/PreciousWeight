package precious_weight.interfaces;

import precious_weight.models.ScaleModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface iScale extends JpaRepository<ScaleModel, Integer> {
}
