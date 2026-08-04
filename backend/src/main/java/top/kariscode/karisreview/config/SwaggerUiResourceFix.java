package top.kariscode.karisreview.config;

import org.springdoc.core.properties.SwaggerUiConfigProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * springdoc 2.8.17+ 在 Spring Boot 3.4 上生成非法 PathPattern，
 * 且会调用 Spring 6.2.0 不存在的内部方法。
 * 这里关闭 springdoc 的 UI 自动配置，仅保留 API 文档接口，
 * 并用独立的静态资源映射提供 Swagger UI。
 */
@Configuration
@ConditionalOnProperty(name = "springdoc.swagger-ui.enabled", havingValue = "true")
public class SwaggerUiResourceFix {

    @Bean
    WebMvcConfigurer swaggerUiResourceHandler(SwaggerUiConfigProperties properties) {
        return new WebMvcConfigurer() {
            @Override
            public void addResourceHandlers(ResourceHandlerRegistry registry) {
                String webjarLocation = "classpath:/META-INF/resources/webjars/swagger-ui/"
                        + properties.getVersion() + "/";
                registry.addResourceHandler("/swagger-ui/**")
                        .addResourceLocations("classpath:/static/swagger-ui/", webjarLocation);
            }

            @Override
            public void addViewControllers(ViewControllerRegistry registry) {
                registry.addRedirectViewController("/swagger-ui.html", "/swagger-ui/index.html");
            }
        };
    }
}
