package precious.weight.spring.security.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import precious.weight.spring.security.entities.Tweet;

@Repository
public interface TweetRepository extends JpaRepository<Tweet, Long> {

}