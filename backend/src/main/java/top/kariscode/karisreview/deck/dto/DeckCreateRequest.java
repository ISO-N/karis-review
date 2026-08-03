package top.kariscode.karisreview.deck.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class DeckCreateRequest {

    @NotBlank(message = "{validation.deck.name.notblank}")
    @Size(min = 1, max = 100, message = "{validation.deck.name.length}")
    private String name;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
}