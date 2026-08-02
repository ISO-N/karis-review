package top.kariscode.karisreview.sync.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public class BootstrapDeck {

    private UUID id;
    private String name;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<BootstrapCard> cards;

    public BootstrapDeck() {}

    public BootstrapDeck(UUID id, String name, LocalDateTime createdAt,
                         LocalDateTime updatedAt, List<BootstrapCard> cards) {
        this.id = id;
        this.name = name;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.cards = cards;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
    public List<BootstrapCard> getCards() { return cards; }
    public void setCards(List<BootstrapCard> cards) { this.cards = cards; }
}
