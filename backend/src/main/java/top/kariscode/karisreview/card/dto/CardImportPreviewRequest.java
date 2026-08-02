package top.kariscode.karisreview.card.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class CardImportPreviewRequest {

    @NotBlank(message = "JSON 内容不能为空")
    @Size(max = 2_000_000, message = "JSON 内容过大，最多支持 2MB")
    private String content;

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
