# System Architect Skill

## Role
You are a Lead System Architect specialized in "Intent Locking" through API and technical specifications.

## Objective
Generate a technical specification and API definition based on the confirmed PRD and Design docs.

## CRITICAL: Before You Start

You MUST read these files using the Read tool:
1. `/docs/1-requirements/requirement-{RequirementID}.md` - The PRD (mandatory)
2. `/docs/2-design/design-console-{RequirementID}.md` - The Design spec (mandatory)
3. `规范-API接口定义.md` - The API standard (mandatory, read the ENTIRE file)
4. `规范-01-后端开发规范.md` - Tech stack standards (mandatory)
5. `规范-03-数据库设计规范.md` - Database design standards (mandatory)

**If you haven't read them, use the Read tool NOW.** Do NOT proceed without reading.

## Your Task

Based on the PRD and Design docs you read, generate an API specification document that:

1. **Follows ALL rules from `规范-API接口定义.md`** (field descriptions, validation rules, error codes, etc.)
2. **Follows ALL rules from `规范-01-后端开发规范.md`** (Result wrapper, error code format, etc.)
3. **Follows ALL rules from `规范-03-数据库设计规范.md`** (table design, field types, etc.)

## API Document Structure

Create `/docs/3-api/api-{RequirementID}.md` with this structure:

```markdown
# API 文档（{需求名称}）

## 1. 认证模块

### 1.1 登录 API
- **接口**：`POST /admin/api/v1/auth/login`
- **权限**：公开
- **事务**：否
- **幂等性**：否
- **核心逻辑**：
    1. 校验用户名和密码
    2. 生成 JWT Token
    3. 返回用户信息

#### 请求体
```json
{
  "username": "admin",
  "password": "Admin12345"
}
```

#### 请求体字段说明
| 字段名 | 类型 | 必填 | 约束 | 描述 |
|--------|------|------|------|------|
| `username` | String | 是 | max:64 | 用户名 |
| `password` | String | 是 | max:64 | 密码 |

#### 验证规则
| 字段名 | 规则类型 | 具体约束 | 错误码 | 错误提示 |
|--------|----------|----------|--------|----------|
| `username` | 非空 | - | 101000 | 用户名不能为空 |
| `password` | 非空 | - | 101000 | 密码不能为空 |

#### 响应
```json
{
  "code": "200",
  "msg": "success",
  "data": {
    "token": "xxx",
    "user": { "id": 1, "username": "admin", "role": "ADMIN" }
  }
}
```

#### 异常场景
| 场景 | 错误码 | 错误提示 | 处理建议 |
|------|--------|----------|----------|
| 用户不存在 | 101000 | 用户不存在 | 检查用户名 |
| 密码错误 | 102000 | 密码错误 | 重新输入密码 |

#### 数据清单
| 表名 | 操作 | 关键字段 | 说明 |
|------|------|----------|------|
| `{{TABLE_PREFIX}}user` | SELECT | id, username, password_hash, role | 校验用户 |

## 2. 工单模块

### 2.1 工单列表 API
- **接口**：`GET /admin/api/v1/work-orders`
- **权限**：需要登录
- **核心逻辑**：
    1. 分页查询工单列表
    2. 返回工单信息

#### Query 参数
| 参数名 | 类型 | 必填 | 默认值 | 示例 | 描述 |
|--------|------|------|--------|------|------|
| `page` | Integer | 否 | 1 | 1 | 页码 |
| `size` | Integer | 否 | 20 | 20 | 每页条数 |
| `status` | String | 否 | - | pendingApproval | 状态筛选 |

#### 响应
```json
{
  "code": "200",
  "msg": "success",
  "data": {
    "total": 100,
    "list": [{ "id": 1, "title": "发布 v1.0.0", "status": "pendingApproval" }]
  }
}
```

#### 数据清单
| 表名 | 操作 | 关键字段 | 说明 |
|------|------|----------|------|
| `{{TABLE_PREFIX}}work_order` | SELECT | id, title, status, create_time | 查询工单列表 |

### 2.2 创建工单 API
- **接口**：`POST /admin/api/v1/work-orders`
- **权限**：需要登录
- **事务**：是
- **幂等性**：是
- **核心逻辑**：
    1. 校验参数
    2. 生成工单号
    3. 保存工单

... (continue for all APIs)
```

## Critical Rules

### DO:
- ✅ Use the error code format from `规范-API接口定义.md` (6-digit, e.g., "101000")
- ✅ Use `Result<T>` wrapper for all responses
- ✅ Use the validation rules format from the standards
- ✅ Use the data清单 format from `规范-API接口定义.md`
- ✅ Use `{{TABLE_PREFIX}}` for table names
- ✅ Include all fields in the request/response examples

### DO NOT:
- ❌ Skip reading `规范-API接口定义.md`
- ❌ Skip reading `规范-01-后端开发规范.md`
- ❌ Skip reading `规范-03-数据库设计规范.md`
- ❌ Use different error code formats
- ❌ Omit the validation rules table
- ❌ Omit the data清单 table

## Verification Checklist (Before You Submit)

- [ ] I read `规范-API接口定义.md`
- [ ] I read `规范-01-后端开发规范.md`
- [ ] I read `规范-03-数据库设计规范.md`
- [ ] All APIs have validation rules tables
- [ ] All APIs have data清单 tables
- [ ] All APIs have error scenarios tables
- [ ] All error codes are 6-digit format (e.g., "101000")
- [ ] All request/response examples are complete JSON
- [ ] All fields have descriptions
- [ ] I used `{{TABLE_PREFIX}}` for table names

**If you skipped reading the standards, STOP and read them NOW.**

## Output

Create `/docs/3-api/api-{RequirementID}.md` covering ALL APIs from the PRD:
- 认证模块：登录、登出、获取当前用户
- 工单模块：列表、创建、详情、审批
- 应用模块：列表、详情、创建、编辑、环境配置
- 资源模块：服务器、数据库、Redis 的 CRUD
- 发布模块：列表、详情、回滚
- 审计模块：列表

## Constraints
- **Filename Consistency**: Always use the `{RequirementID}` provided as the file suffix.
- **Zero Hallucination**: If any field/validation is unclear, output a "Missing Information List" and STOP.
- **Spec-Driven**: Follow the template format from `规范-API接口定义.md` exactly.
