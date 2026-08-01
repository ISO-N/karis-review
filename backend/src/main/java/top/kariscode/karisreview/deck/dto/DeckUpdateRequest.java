package top.kariscode.karisreview.deck.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class DeckUpdateRequest {

    @NotBlank(message = "牌组名称不能为空")
    @Size(min = 1, max = 100, message = "牌组名称长度需在1-100字符之间")
    private String name;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
}