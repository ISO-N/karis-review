package top.kariscode.karisreview.deck.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.deck.entity.Deck;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeckRepository extends JpaRepository<Deck, UUID> {
    List<Deck> findByUserIdOrderByCreatedAtAsc(UUID userId);
    Optional<Deck> findByIdAndUserId(UUID id, UUID userId);
    boolean existsByIdAndUserId(UUID id, UUID userId);
    long countByUserId(UUID userId);
}