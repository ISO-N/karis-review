package top.kariscode.karisreview.card.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class CardImportPreviewRequest {

    @NotBlank(message = "{validation.card.import.json.notblank}")
    @Size(max = 2_000_000, message = "{validation.card.import.json.too.large}")
    private String content;

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
