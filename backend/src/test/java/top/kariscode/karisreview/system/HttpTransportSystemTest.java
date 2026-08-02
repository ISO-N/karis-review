package top.kariscode.karisreview.system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import top.kariscode.karisreview.proto.KarisReviewProto.SyncResponse;

import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class HttpTransportSystemTest extends SystemTestSupport {

    @org.springframework.boot.test.web.server.LocalServerPort
    private int port;

    @Test
    void jsonResponsesAreGzipCompressed() throws Exception {
        TestAccount account = register("transport");
        String token = account.token();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:" + port + "/api/sync/bootstrap"))
                .header("Authorization", "Bearer " + token)
                .header("Accept", "application/json")
                .header("Accept-Encoding", "gzip")
                .GET()
                .build();

        HttpResponse<byte[]> response = HttpClient.newHttpClient()
                .send(request, HttpResponse.BodyHandlers.ofByteArray());

        assertTrue(response.headers().firstValue("Content-Encoding")
                .orElse("").contains("gzip"));
        assertTrue(response.body().length > 0);
    }

    @Test
    void protobufContentNegotiationReturnsBinarySyncResponse() throws Exception {
        TestAccount account = register("transport-proto");
        String token = account.token();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:" + port + "/api/sync/bootstrap"))
                .header("Authorization", "Bearer " + token)
                .header("Accept", "application/x-protobuf")
                .header("Accept-Encoding", "identity")
                .GET()
                .build();

        HttpResponse<byte[]> response = HttpClient.newHttpClient()
                .send(request, HttpResponse.BodyHandlers.ofByteArray());

        assertEquals(200, response.statusCode());
        assertTrue(response.headers().firstValue("Content-Type")
                .orElse("").contains("application/x-protobuf"));
        SyncResponse parsed = SyncResponse.parseFrom(
                new ByteArrayInputStream(response.body()));
        assertNotNull(parsed.getUser());
        assertTrue(parsed.getEventCursor() > 0);
    }

    @Test
    void stableDeckListSupportsEtag304() throws Exception {
        TestAccount account = register("transport-etag");
        String token = account.token();
        data("POST", "/decks", token, Map.of("name", "ETag 牌组"));

        HttpClient http = HttpClient.newHttpClient();
        HttpRequest first = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:" + port + "/api/decks"))
                .header("Authorization", "Bearer " + token)
                .header("Accept", "application/json")
                .header("Accept-Encoding", "identity")
                .GET()
                .build();
        HttpResponse<String> firstResponse = http.send(
                first, HttpResponse.BodyHandlers.ofString());
        assertEquals(200, firstResponse.statusCode());
        String etag = firstResponse.headers().firstValue("ETag").orElse(null);
        assertNotNull(etag);

        HttpRequest second = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:" + port + "/api/decks"))
                .header("Authorization", "Bearer " + token)
                .header("Accept", "application/json")
                .header("If-None-Match", etag)
                .header("Accept-Encoding", "identity")
                .GET()
                .build();
        HttpResponse<String> secondResponse = http.send(
                second, HttpResponse.BodyHandlers.ofString());
        assertEquals(304, secondResponse.statusCode());
    }
}
