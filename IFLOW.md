# iFlow CLI 交互指南 - containerd 项目

## 项目概述

**containerd** 是一个行业标准的容器运行时，专注于简单性、健壮性和可移植性。作为 CNCF 的毕业项目，它是容器生态系统中的核心基础设施组件。

### 核心技术信息
- **主要语言**: Go
- **项目版本**: v2.x
- **许可证**: Apache 2.0
- **主要二进制文件**: 
  - `containerd` - 容器运行时守护进程
  - `ctr` - 简单的测试客户端
  - `containerd-stress` - 压力测试工具

### 项目结构
```
/Users/wf09/Desktop/code/containerd/
├── api/              # Protobuf 服务定义和类型
├── client/           # containerd Go 客户端
├── cmd/              # Go main 包和命令行工具
├── contrib/          # 外部工具和库相关文件
├── core/             # 核心 Go 包，包含接口定义
├── docs/             # 技术文档
├── integration/      # 集成测试
├── internal/         # 内部工具包
├── plugins/          # containerd 插件
├── script/           # 测试、开发和CI脚本
└── vendor/           # 依赖包管理
```

## 构建和运行

### 系统要求
- **Go 编译器**: 支持最新的两个主要版本 (当前需要 Go 1.24.x)
- **Protoc 3.x**: Google protobuf 编译器
- **Btrfs 头文件**: 可选，用于Btrfs快照支持
- **runc**: 默认容器运行时

### 基本构建命令
```bash
# 克隆项目
git clone https://github.com/containerd/containerd

# 构建所有项目二进制文件
make

# 安装到系统路径
sudo make install

# 生成API代码
make generate

# 运行所有非集成测试
make test

# 运行集成测试
make integration

# 生成覆盖率报告
make coverage
```

### 高级构建选项
```bash
# 构建静态二进制文件
make STATIC=1

# 使用特定构建标签
BUILDTAGS=no_btrfs make

# 自定义安装前缀
make install PREFIX=/custom/path

# 运行需要root权限的测试
make root-test

# 运行CRI集成测试
make cri-integration
```

### 开发环境设置
```bash
# 安装开发工具
script/setup/install-dev-tools

# 安装CRI依赖
make install-deps

# 检查代码风格
make check

# 更新vendor目录
make vendor
```

### 关键测试命令
```bash
# 运行特定测试
go test -v -run "TestContainerList" ./integration/client -test.root

# 并行运行集成测试
make integration TESTFLAGS_PARALLEL=1

# 生成代码覆盖率
make coverage
make root-coverage
```

## 开发约定和最佳实践

### 代码风格规范
- **Go文件**: 使用标准Go格式化和样式
- **Protobuf文件**: 使用制表符缩进
- **其他文件**: 不包含尾随空格，以单个换行符结束
- **包命名**: 简洁明了，避免使用`_`和重复父目录词汇

### 目录组织规范
- `api/` - 所有protobuf服务定义和类型
- `bin/` - 构建时自动生成，不提交到版本控制
- `client/` - containerd Go客户端代码
- `cmd/` - Go主包和命令行工具
- `contrib/` - 外部工具、配置和库
- `core/` - 核心Go包和内置实现
- `docs/` - 技术文档（markdown格式）
- `internal/` - 内部工具包，不供外部导入
- `plugins/` - 通过init注册的containerd插件
- `script/` - 测试、开发和CI脚本
- `test/` - 外部端到端测试脚本
- `vendor/` - 自动生成的vendor文件

### 构建和测试
```bash
# 验证代码风格
make check

# 运行所有检查（包括linting）
make ci

# 完整发布构建
make release

# 清理构建产物
make clean
```

### 版本管理
- 使用语义化版本控制
- 版本信息在 `version/` 包中管理
- Git标签用于标记发布版本

## 常用工作流

### 新功能开发
1. 创建功能分支: `git checkout -b feature/new-feature`
2. 开发和测试
3. 运行代码检查: `make check`
4. 更新相关文档
5. 提交PR

### Bug修复
1. 创建bug修复分支: `git checkout -b fix/bug-description`
2. 编写测试用例验证bug
3. 修复bug并确保测试通过
4. 运行完整的测试套件: `make test && make integration`

### API更改
1. 修改`.proto`文件
2. 运行 `make protos` 重新生成API代码
3. 更新相关客户端代码
4. 运行 `make check-protos` 验证更改

## 重要文件和配置

### 核心配置文件
- `go.mod` - Go模块依赖定义
- `Makefile` - 主要构建和开发任务
- `BUILDING.md` - 详细构建说明
- `CONTRIBUTING.md` - 贡献指南

### 平台特定文件
- `Makefile.darwin` - macOS特定构建配置
- `Makefile.linux` - Linux特定构建配置
- `Makefile.windows` - Windows特定构建配置

### 文档文件
- `docs/` - 完整技术文档
- `RELEASES.md` - 发布说明
- `docs/cri/` - CRI插件特定文档

## 贡献指南

### 开始贡献
1. 阅读[containerd项目贡献指南](https://github.com/containerd/project/blob/main/CONTRIBUTING.md)
2. 设置开发环境
3. 查看[BUILDING.md](BUILDING.md)了解开发环境配置
4. 查找标记为`exp/beginner`的新手友好issue

### 提交要求
- 所有代码必须通过`make check`
- 所有新功能需要添加测试
- 遵循Go编码标准
- 更新相关文档

### 测试要求
- 单元测试: `make test`
- 集成测试: `make integration`
- 性能测试: `make benchmark`
- 代码覆盖率: `make coverage`

## 故障排除

### 常见构建问题
1. **Go版本不匹配**: 确保使用支持的Go版本
2. **protoc缺失**: 安装protoc 3.x编译器
3. **依赖问题**: 运行 `make vendor` 更新依赖
4. **权限问题**: 某些测试需要root权限，使用`sudo`

### 测试问题
1. **集成测试失败**: 确保所有依赖已安装 (`make install-deps`)
2. **网络测试失败**: 检查网络连接和镜像拉取权限
3. **容器清理问题**: 运行 `make clean-test` 清理测试残留

## 资源链接

- [官方文档](https://containerd.io)
- [GitHub仓库](https://github.com/containerd/containerd)
- [API文档](https://pkg.go.dev/github.com/containerd/containerd/v2)
- [CI状态](https://github.com/containerd/containerd/actions)
- [社区联系](https://cloud-native.slack.com) (#containerd频道)

## 下一步行动

1. 阅读BUILDING.md了解详细构建说明
2. 查看CONTRIBUTING.md了解贡献流程
3. 浏览docs/目录了解更多技术细节
4. 查看integration/目录了解测试结构
5. 订阅#containerd Slack频道参与社区讨论

---
*此文档为iFlow CLI交互生成，用于指导containerd项目的开发和管理。*