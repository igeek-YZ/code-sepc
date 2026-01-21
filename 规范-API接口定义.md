# 后端 API 接口定义规范

本文档旨在统一后端 API 接口的设计格式与内容规范，确保接口文档的清晰性、一致性及可维护性。所有新开发的 API 接口均需遵循此规范。

## 一、 接口文档结构

每个 API 接口的定义应包含以下核心要素：

1.  **接口名称**：清晰简练地描述接口功能（如：商品列表 API）。
2.  **接口地址 (URL)**：HTTP 方法与路径（如：`GET /api/products`）。
3.  **请求参数 (Request Parameters)**：
    *   **Query/Path 参数**：URL 路径参数或查询字符串参数。
    *   **请求体 (Request Body)**：JSON 格式的请求数据结构。
    *   **字段说明**： Query/Path 参数/请求体 字段说明。
4.  **安全与权限 (Security & Permission)**：明确接口的鉴权方式及权限要求。
5.  **验证规则 (Validation Rules)**：详细列出参数的校验逻辑、必填项、格式要求及业务约束。
6.  **响应结果 (Response)**：
    *   成功响应的 JSON 结构示例。
    *   包含标准的状态码 (`code`)、提示信息 (`message`) 及数据载荷 (`data`)。
    *   **字段说明**：
        *   `code`：状态码，200 表示成功，其他值表示错误。
        *   `message`：对状态码的详细描述，用于客户端展示。
        *   `data`：包含实际业务数据的 JSON 对象。

---

## 二、 详细规范说明

### 1. 接口命名
*   **格式**：`{资源名称} + {操作} + API`
*   **示例**：
    *   `商品列表 API`
    *   `代理商添加 API`
    *   `验证码发送 API`

### 2. URL 设计
*   **风格**：RESTful 风格。
*   **前缀**：统一使用 `/api` 作为 API 路径前缀。
*   **资源命名**：使用复数名词表示资源集合（如 `/products`, `/agents`），使用单数名词表示特定操作或资源（如 `/auth/login`）。
*   **路径参数**：使用 `{paramName}` 表示动态路径参数（如 `/api/products/{skuCode}`）。

### 3. 请求定义

#### 3.1 Query / Path 参数
*   **适用场景**：GET 请求筛选、分页，或 RESTful 路径资源定位。
*   **示例**：`GET /api/products?page=1&status=ON_SALE`
*   **字段说明**：
    | 参数名 | 类型 | 必填 | 默认值 | 示例值 | 描述 |
    | :--- | :--- | :--- | :--- | :--- | :--- |
    | `page` | Integer | 否 | 1 | 1 | 分页页码 |
    | `pageSize` | Integer | 否 | 10 | 20 | 每页条数 |
    | `skuCode` | String | 否 | - | "SKU123" | 精确匹配商品编码 |
    | `status` | String | 否 | - | "ON_SALE" | 状态枚举值 |

#### 3.2 请求体 (Request Body)
*   **适用场景**：POST/PUT/PATCH 请求传输复杂结构化数据。
*   **格式**：application/json
*   **JSON 结构示例**：
    ```json
    {
      "skuName": "iPhone 15",
      "price": "5999.00",
      "tags": ["新品", "热销"],
      "specs": { "color": "black", "storage": "128G" }
    }
    ```
*   **字段说明**：
    | 字段名 | 类型 | 必填 | 约束/枚举 | 描述 |
    | :--- | :--- | :--- | :--- | :--- |
    | `skuName` | String | 是 | max:100 | 商品名称 |
    | `price` | String | 是 | >0, 2位小数 | 价格（字符串格式防精度丢失） |
    | `tags` | Array<String> | 否 | max:5 | 标签列表 |
    | `specs` | Object | 否 | - | 规格属性对象 |

### 4. 业务规则与边界 (Business Rules & Edge Cases)
*   **核心逻辑**：简述接口的核心处理流程（如：校验库存 -> 扣减余额 -> 创建订单）。
*   **状态流转**：涉及状态变更时，需明确“前置状态”和“后置状态”（如：仅`PENDING`状态可取消）。
*   **边界条件**：
    *   **并发控制**：是否需要锁？（如：抢购场景）
    *   **幂等性**：重复请求如何处理？（如：支付回调）
    *   **数据权限**：用户只能操作自己的数据吗？
*   **异常场景**：
    | 场景 | 错误码 | 错误提示 | 处理建议 |
    | :--- | :--- | :--- | :--- |
    | 库存不足 | 400101 | "商品库存不足" | 提示用户减少数量 |
    | 余额不足 | 400201 | "账户余额不足" | 跳转充值页 |
### 5. 安全与权限 (Security & Permission)
*   **鉴权方式**：默认需携带 JWT Token（Header: `Authorization: Bearer {token}`）。
*   **权限注解**：明确对应的后端权限注解，便于 AI 生成安全代码。
*   **请求频次限制**：默认每个用户每个接口每 1 秒最多调用 2 次，可根据业务场景调整。
*   **幂等性**：对于涉及资金或状态流转的关键接口（如加购、支付、下单），需明确是否需要幂等性控制。
*   **示例**：
    *   需要登录：`@PreAuthorize("isAuthenticated()")`
    *   需要特定角色：`@PreAuthorize("hasRole('ADMIN')")`
    *   需要幂等性：`@Idempotent`
    *   需要接口频次限制：`@RateLimit(limit = 2, perSecond = 1)`

### 6. 验证规则 (Validation Rules)
*   这是接口文档中**最关键**的部分，需明确列出：
    *   **非空校验**：哪些字段必填。
    *   **格式校验**：如邮箱格式、手机号格式、身份证格式。
    *   **业务逻辑校验**：
        *   引用表是否存在（如：检查邮箱是否在代理商表中存在）。
        *   数值范围约束（如：价格 > 0）。
        *   状态约束（如：采购单状态只能是待付款/已完成）。
        *   唯一性约束（如：采购单号已存在则报错）。
    *   **错误提示与错误码**：
        *   明确验证失败时的报错文案（如：【邮箱无效，请联系品牌方】）。
        *   建议指定异常类型（如 `BusinessException`）及错误码（如 `USER_NOT_FOUND`）。

### 7. 响应定义
*   **统一格式**：
    ```json
    {
      "code": 200,
      "message": "操作成功",  // 可选，仅在非查询类接口或报错时强调
      "data": { ... }        // 成功时的数据载荷
    }
    ```
*   **Swagger/Knife4j 注解规范**：
    *   Controller 类：`@Tag(name = "xxx")`
    *   接口方法：`@Operation(summary = "xxx")`
    *   参数对象：`@Schema(description = "xxx")`
*   **列表数据**：需包含分页信息 `total` 和数据列表 `list`。
    ```json
    { "total": 100, "list": [{ ... }] }
    ```

### 8. 代码生成指引 - for AI
为了避免代码生成过程中的理解偏移，请严格遵守以下实现细节：

1.  **对象边界 (Object Boundary)**：
    *   **严禁**在 Controller 接口中使用数据库实体 (`Entity`) 作为参数或返回值。
    *   **请求参数**：必须封装为独立的 DTO 类（命名后缀建议 `Req` 或 `DTO`，如 `UserCreateReq`）。
    *   **响应结果**：必须封装为独立的 VO 类（命名后缀建议 `Resp` 或 `VO`，如 `UserResp`）。
    *   需生成 Entity 与 DTO/VO 之间的转换代码（使用 MapStruct）。

2.  **分页结构适配**：
    *   后端使用 MyBatis-Plus 的 `Page<T>` 对象进行查询。
    *   **排序要求**：所有分页查询接口，默认**必须**按照 `ID` 进行降序排列 (`ORDER BY id DESC`)，以确保数据的一致性和新数据优先展示。除非业务明确指定了其他排序字段（如 `created_time` 或 `sort_order`）。
    *   **必须**经过转换层，将 `Page` 对象的 `records` 字段映射为 API 文档要求的 `list` 字段。
    *   建议定义通用的 `PageResult<T>` 包装类：
        ```java
        @Data
        public class PageResult<T> {
            private long total;
            private List<T> list;
        }
        ```

3.  **校验逻辑分层**：
    *   **格式校验**（非空、长度、正则）：在 Controller 层使用 JSR-303 注解 (`@NotNull`, `@Pattern`) 处理。
    *   **业务校验**（唯一性、数据库状态）：**必须**下沉到 Service 层实现。Controller 仅负责调用 Service，不处理具体的业务判断逻辑。

4.  **异常与错误码**：
    *   所有业务校验失败，**必须**抛出 `BusinessException`。
    *   错误码枚举类统一命名为 `BizCodeEnum` (或复用项目中已有的枚举)，禁止直接硬编码错误码数字或随意创建新枚举类。

5.  **枚举处理**：
    *   接收参数：使用 MyBatis-Plus 的 `@EnumValue` 或 Spring 的 `Converter` 自动处理 `code` 到 `Enum` 的转换，避免在 Controller 中写 `switch/case`。

---

## 三、 标准示例模板

以下是一个标准的 API 定义示例，请在编写文档时直接复用此模板：

### {模块名称} API

#### 1. {接口名称} API
- **接口**：`{METHOD} /api/{resource}/{action}`
- **权限**：需要 {角色/权限} (`@PreAuthorize("...")`)
- **事务**：是/否 (如涉及多表写操作，需标注 `@Transactional`)
- **幂等性**：是/否(默认否，GET接口不需要幂等性)
- **核心逻辑**：
    1.  校验...
    2.  计算...
    3.  更新...
- **参数**：
    | 参数名 | 类型 | 必填 | 示例 | 描述 |
    | :--- | :--- | :--- | :--- | :--- |
    | `id` | Long | 是 | 1 | ID |
- **请求体**：
    ```json
    { "field1": "value" }
    ```
- **请求体字段**：
    | 字段名 | 类型 | 必填 | 约束 | 描述 |
    | :--- | :--- | :--- | :--- | :--- |
    | `field1` | String | 是 | max:50 | 说明 |
- **验证规则**：
  - {规则1}：{field1} 非空
  - {规则2}：{field2} 必须符合 {格式}
- **异常场景**：
  - 找不到数据 -> 404
- **响应**：
  ```json
  {
    "code": 200,
    "message": "操作成功",
    "data": { ... }
  }
  ```

---

## 四、 现有接口参考 (Based on 后端功能API.md)

### 商品添加 API (示例)
- **接口**：`POST /api/product/add`
- **请求体**：`{ skuCode, skuName, brand, price, totalStock }`
- **字段说明**：
  | 字段名 | 类型 | 是否必填 | 描述 |
  | :--- | :--- | :--- | :--- |
  | `skuCode` | String | 是 | 商品 SKU 编码，唯一标识。 |
  | `skuName` | String | 是 | 商品名称。 |
  | `brand` | String | 是 | 品牌名称。 |
  | `price` | String | 是 | 商品价格，大于 0。 |
  | `totalStock` | Integer | 是 | 总库存，大于等于 0。 |
- **验证规则**：
  - skuCode 非空
  - skuName 非空
  - brand 非空
  - 价格 > 0
  - 总库存 ≥ 0
- **响应**：`{ code: 200, message: '商品添加成功' }`
