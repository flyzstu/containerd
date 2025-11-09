# --image-registry 功能说明

## 概述

`--image-registry` 是一个新添加的CLI参数，允许用户指定默认的镜像仓库域名，而不使用默认的 `docker.io`。

## 功能特性

1. **自定义默认镜像仓库**: 用户可以通过 `--image-registry` 参数指定自己的镜像仓库
2. **自动镜像名称规范化**: 自动为裸镜像名称添加指定的默认注册表
3. **向后兼容**: 如果不指定 `--image-registry`，行为与之前完全一致
4. **支持环境变量**: 同时支持通过 `CONTAINERD_DEFAULT_IMAGE_REGISTRY` 环境变量设置

## 使用方法

### 1. 基础使用

```bash
# 使用自定义镜像仓库
ctr images pull --image-registry my-registry.com ubuntu:latest

# 等价于
ctr images pull --image-registry my-registry.com my-registry.com/ubuntu:latest
```

### 2. 支持的命令

这个参数支持所有镜像相关的命令：

```bash
# 拉取镜像
ctr images pull --image-registry registry.example.com alpine:latest

# 运行容器
ctr run --image-registry registry.example.com --rm -t ubuntu:latest ubuntu

# 推送镜像
ctr images push --image-registry registry.example.com ubuntu:latest registry.example.com/ubuntu:latest
```

### 3. 环境变量方式

```bash
# 设置环境变量
export CONTAINERD_DEFAULT_IMAGE_REGISTRY=my-registry.com

# 现在拉取镜像时会自动使用 my-registry.com 作为默认注册表
ctr images pull ubuntu:latest
```

## 参数行为详解

### 镜像名称处理逻辑

1. **已有注册表的镜像**: 如果镜像名称已经包含注册表域名，参数会被忽略
   ```bash
   # 这些镜像已经有注册表，--image-registry 参数会被忽略
   ctr images pull --image-registry my-registry.com docker.io/library/ubuntu:latest
   ctr images pull --image-registry my-registry.com registry.k8s.io/nginx
   ```

2. **裸镜像名称**: 自动添加指定的默认注册表
   ```bash
   # 如果指定 --image-registry my-registry.com
   ctr images pull ubuntu:latest
   # 实际被处理为: my-registry.com/ubuntu:latest
   ```

3. **默认行为**: 如果不指定 `--image-registry`，使用原始的 docker.io
   ```bash
   # 默认行为保持不变
   ctr images pull ubuntu:latest
   # 等价于: docker.io/library/ubuntu:latest
   ```

## 实现细节

### 新增的函数

1. `GetDefaultImageRegistry(cliContext *cli.Context) string`:
   - 从CLI上下文中获取 `--image-registry` 参数
   - 如果没有指定，返回默认值 "docker.io"

2. `ImageNameWithDefaultRegistry(cliContext *cli.Context, imageName string) string`:
   - 智能处理镜像名称，添加默认注册表
   - 避免重复添加已存在的注册表

### 修改的文件

1. `cmd/ctr/commands/commands.go`:
   - 在 `RegistryFlags` 中添加 `--image-registry` 标志
   - 添加相关的辅助函数：`GetDefaultImageRegistry()` 和 `ImageNameWithDefaultRegistry()`

2. `cmd/ctr/commands/images/pull.go`:
   - 修改镜像名称处理逻辑使用 `ImageNameWithDefaultRegistry()`

3. `cmd/ctr/commands/run/run.go`:
   - 修改容器运行时镜像名称处理

4. `cmd/ctr/commands/images/push.go`:
   - 修改推送镜像名称处理

5. `core/remotes/docker/resolver.go`:
   - 添加 `GetDefaultRegistry()` 函数用于环境变量支持
   - 修改 `DefaultHost()` 函数以支持环境变量检查

6. `core/remotes/docker/config/hosts.go`:
   - 在配置主机解析时支持环境变量
   - 确保自定义注册表在底层解析中正确处理

### 关键修复

**问题**: 初始实现中 `GetDefaultRegistry()` 函数没有被调用，导致环境变量支持失效。

**修复**: 
- 修改 `DefaultHost()` 函数，使其使用 `GetDefaultRegistry()` 函数
- 在 `core/remotes/docker/config/hosts.go` 中也使用 `GetDefaultRegistry()` 函数
- 确保整个解析流程都支持环境变量和CLI参数

**验证**: `GetDefaultRegistry()` 函数现在在以下位置被调用:
- `core/remotes/docker/resolver.go:135` (DefaultHost函数)
- `core/remotes/docker/config/hosts.go:101` (配置解析)

**结果**: 现在 CLI 参数和環境变量都能在所有层级的解析中生效，包括:
- CLI 层面的镜像名称规范化 (`ImageNameWithDefaultRegistry()`)
- 底层的默认主机解析 (`DefaultHost()`)
- 主机配置解析 (`ConfigureHosts()`)
- CRI 组件中的解析逻辑

**完整流程**:
1. 用户设置环境变量或使用CLI参数
2. CLI层面通过 `ImageNameWithDefaultRegistry()` 处理镜像名称
3. 底层通过 `DefaultHost()` 和配置解析使用 `GetDefaultRegistry()`
4. 所有层级的解析都支持自定义注册表

## 兼容性

- **向后兼容**: 完全兼容现有工作流
- **参数优先**: CLI 参数 `--image-registry` 优先于环境变量
- **Docker 兼容**: 保持与 Docker 镜像命名规范的兼容

## 使用场景

1. **企业内部镜像仓库**: 使用私有注册表
2. **镜像代理**: 指向镜像代理/缓存服务
3. **多镜像仓库环境**: 在不同项目中使用不同默认注册表
4. **开发和测试**: 快速切换到测试环境镜像仓库

## 注意事项

1. 参数仅影响没有明确注册表的镜像名称
2. 绝对镜像名称（有完整路径的）不受影响
3. 与现有的 `hosts-dir` 和其他注册表配置参数一起工作
4. 建议在脚本中使用环境变量方式，更便于维护