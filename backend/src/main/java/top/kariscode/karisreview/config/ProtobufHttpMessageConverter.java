package top.kariscode.karisreview.config;

import com.google.protobuf.Message;
import org.springframework.http.HttpInputMessage;
import org.springframework.http.HttpOutputMessage;
import org.springframework.http.MediaType;
import org.springframework.http.converter.AbstractHttpMessageConverter;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Method;

@Component
public class ProtobufHttpMessageConverter extends AbstractHttpMessageConverter<Message> {

    public static final MediaType APPLICATION_X_PROTOBUF =
            new MediaType("application", "x-protobuf");
    public static final String APPLICATION_X_PROTOBUF_VALUE = "application/x-protobuf";
    public ProtobufHttpMessageConverter() {
        super(APPLICATION_X_PROTOBUF, MediaType.APPLICATION_OCTET_STREAM);
    }

    @Override
    protected boolean supports(Class<?> clazz) {
        return Message.class.isAssignableFrom(clazz);
    }

    @Override
    protected Message readInternal(Class<? extends Message> clazz,
                                   HttpInputMessage inputMessage)
            throws IOException, HttpMessageNotReadableException {
        try {
            Method parseFrom = clazz.getMethod("parseFrom", InputStream.class);
            return (Message) parseFrom.invoke(null, inputMessage.getBody());
        } catch (ReflectiveOperationException e) {
            throw new HttpMessageNotReadableException(
                    "server.protobuf.parse.failed", e, inputMessage);
        }
    }

    @Override
    protected void writeInternal(Message message, HttpOutputMessage outputMessage)
            throws IOException {
        message.writeTo(outputMessage.getBody());
    }

    @Override
    protected Long getContentLength(Message message, MediaType contentType) {
        return (long) message.getSerializedSize();
    }
}
