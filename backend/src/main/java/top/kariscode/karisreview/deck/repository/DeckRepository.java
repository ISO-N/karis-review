package top.kariscode.karisreview.deck.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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

    /**
     * 按用户批量删除全部卡组。bulk 删除在数据库层级联删除 cards / review_logs /
     * review_queue_items，且逐行触发 sync_events 记录，与逐条 delete 行为一致，
     * 但避免 N 次 JDBC 往返。
     */
    @Modifying
    @Query("DELETE FROM Deck d WHERE d.userId = :userId")
    int deleteAllByUserId(@Param("userId") UUID userId);
}
