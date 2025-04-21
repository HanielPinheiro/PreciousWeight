package precious_weight.interfaces;

import precious_weight.controllers.ScaleController;
import precious_weight.models.ScaleModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface iScale extends JpaRepository<ScaleModel, Integer> {
    List<ScaleModel> findByBabyIdIsNotNull();
    List<ScaleModel> findByBabyId(Integer babyId); // Useful if you need this later
}

