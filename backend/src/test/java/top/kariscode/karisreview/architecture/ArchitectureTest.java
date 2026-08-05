package top.kariscode.karisreview.architecture;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * 模块契约固化测试（WP-9 / 架构文档 §3.3）：
 * <ol>
 *   <li>分层依赖：controller 禁止访问 repository；service 禁止依赖 controller；</li>
 *   <li>模块门面：业务模块禁止直接依赖 auth 内部包（entity/repository），
 *       只能通过 {@code auth.api.IdentityPort} 门面访问用户信息；</li>
 *   <li>依赖方向：card/review/sync/backup 单向依赖，stats 纯消费方，严禁循环。</li>
 * </ol>
 *
 * <p>说明：UserLogService（log 模块）是横切基础设施，被所有 Service 使用属设计内依赖，
 * 因此不纳入"分层禁反向"检查；common 允许依赖 log（同为基础设施层）。
 */
@AnalyzeClasses(packages = "top.kariscode.karisreview",
        importOptions = {ImportOption.DoNotIncludeTests.class,
                ImportOption.DoNotIncludeJars.class})
public class ArchitectureTest {

    private static final String BASE = "top.kariscode.karisreview";

    /** 控制器层禁止直接使用 Repository（必须经 Service）。 */
    @ArchTest
    static final ArchRule CONTROLLER_NO_REPOSITORY = noClasses()
            .that().resideInAPackage(BASE + "..controller..")
            .should().dependOnClassesThat().resideInAPackage(BASE + "..repository..")
            .because("Controller 不得直接访问数据访问层，必须经 Service");

    /** 服务层禁止依赖其他模块的 Controller（反向依赖）。 */
    @ArchTest
    static final ArchRule SERVICE_NO_CONTROLLER = noClasses()
            .that().resideInAPackage(BASE + "..service..")
            .should().dependOnClassesThat().resideInAPackage(BASE + "..controller..")
            .because("Service 不得反向依赖 Controller");

    /** Repository 层不得依赖 Service/Controller（数据访问层是叶节点）。 */
    @ArchTest
    static final ArchRule REPOSITORY_IS_LEAF = noClasses()
            .that().resideInAPackage(BASE + "..repository..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    BASE + "..service..", BASE + "..controller..")
            .because("Repository 处于依赖图最底层");

    /**
     * 身份门面：除 auth 与 settings（身份域内部）外，任何模块不得直接依赖
     * auth 的实体/仓储，只能通过 IdentityPort 读取用户信息。
     */
    @ArchTest
    static final ArchRule IDENTITY_FACADE = noClasses()
            .that().resideOutsideOfPackages(BASE + ".auth..", BASE + ".settings..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    BASE + ".auth.entity..", BASE + ".auth.repository..")
            .because("业务模块必须通过 auth.api.IdentityPort 门面访问用户身份（WP-9/M6）");

    /** 依赖图底层模块不得反向依赖上层：card 不依赖 review/stats/sync/backup。 */
    @ArchTest
    static final ArchRule CARD_IS_BOTTOM = noClasses()
            .that().resideInAPackage(BASE + ".card..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    BASE + ".review..", BASE + ".stats..", BASE + ".sync..", BASE + ".backup..")
            .because("card 处于依赖图底层，禁止反向依赖上层模块");

    /** deck 不依赖 review/stats/sync/backup（deck→card 为已确认的设计内依赖）。 */
    @ArchTest
    static final ArchRule DECK_IS_BOTTOM = noClasses()
            .that().resideInAPackage(BASE + ".deck..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    BASE + ".review..", BASE + ".stats..",
                    BASE + ".sync..", BASE + ".backup..")
            .because("deck 处于依赖图底层，不依赖复习/统计/同步/备份模块");

    /** stats 是纯消费方：不得被 review/sync/backup 依赖。 */
    @ArchTest
    static final ArchRule STATS_IS_CONSUMER_ONLY = noClasses()
            .that().resideInAnyPackage(BASE + ".review..", BASE + ".sync..", BASE + ".backup..")
            .should().dependOnClassesThat().resideInAPackage(BASE + ".stats..")
            .because("stats 为数据消费方（事件驱动），上游模块不得依赖它");

    /** common 是基础设施层：不得反向依赖任何业务模块（允许依赖 log 横切模块）。 */
    @ArchTest
    static final ArchRule COMMON_NO_BUSINESS_DEPS = noClasses()
            .that().resideInAPackage(BASE + ".common..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    BASE + ".auth..", BASE + ".deck..", BASE + ".card..",
                    BASE + ".review..", BASE + ".stats..", BASE + ".backup..",
                    BASE + ".settings..", BASE + ".sync..")
            .because("common 是基础设施层，不得反向依赖任何业务模块");

    /** backup 依赖全部业务模块，但不得被它们反向依赖（导出者是终点）。 */
    @ArchTest
    static final ArchRule BACKUP_IS_TERMINAL = noClasses()
            .that().resideInAnyPackage(
                    BASE + ".auth..", BASE + ".deck..", BASE + ".card..",
                    BASE + ".review..", BASE + ".stats..", BASE + ".settings..", BASE + ".sync..")
            .should().dependOnClassesThat().resideInAPackage(BASE + ".backup..")
            .because("backup 是横切导出者，业务模块不得依赖它");
}
