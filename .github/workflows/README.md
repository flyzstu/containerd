# Containerd 多架构构建 GitHub Action

这个 GitHub Action 提供了自动化的 containerd 多架构构建功能。

## 功能特性

- **多架构支持**: Linux AMD64, ARM64, s390x, ppc64le
- **自动版本管理**: 使用 Git commit SHA 作为版本号
- **标准化包格式**: `containerd-<commit_id>-linux-<arch>.tar.gz`
- **完整性校验**: 生成 SHA256 校验和
- **自动发布**: 支持自动发布到 GitHub Releases

## 触发条件

- **Push 到主分支**: 自动构建并上传 artifacts
- **Pull Request**: 构建验证
- **Release 发布**: 自动上传到 GitHub Releases

## 包内容

每个构建的包包含：

```
containerd-<commit_id>-linux-<arch>/
├── bin/
│   ├── ctr                    # containerd CLI 工具
│   ├── containerd            # containerd 守护进程
│   └── containerd-stress     # 压力测试工具
└── etc/
    └── containerd/
        └── config.toml       # 默认配置文件
```

## 使用方法

### 1. 自动化使用

只需要将代码推送到 GitHub，Action 会自动：
- 检测架构
- 构建二进制文件
- 生成压缩包
- 上传 artifacts

### 2. 本地测试

```bash
# 清理之前的构建
make clean

# 设置环境变量
export GOOS=linux
export GOARCH=amd64
export VERSION=$(git rev-parse --short HEAD)
export REVISION=$(git rev-parse HEAD)

# 构建
make binaries

# 验证二进制文件
./bin/ctr --version
./bin/containerd --version
```

### 3. 手动触发

在 GitHub Actions 页面：
1. 点击 "Run workflow"
2. 选择分支
3. 运行工作流

## 架构支持

| 架构 | GOARCH | 描述 |
|------|--------|------|
| AMD64 | amd64 | Intel/AMD 64位 |
| ARM64 | arm64 | ARM 64位 |
| s390x | s390x | IBM System z |
| ppc64le | ppc64le | PowerPC 64位 little-endian |

## 部署指南

```bash
# 1. 下载对应架构的包
wget https://github.com/your-org/containerd/releases/download/v1.0.0/containerd-<sha>-linux-amd64.tar.gz

# 2. 解压
tar -xzf containerd-<sha>-linux-amd64.tar.gz

# 3. 安装二进制文件
sudo cp containerd-<sha>-linux-amd64/bin/* /usr/local/bin/

# 4. 安装配置文件
sudo mkdir -p /etc/containerd
sudo cp containerd-<sha>-linux-amd64/etc/containerd/config.toml /etc/containerd/

# 5. 启动服务
sudo systemctl enable containerd
sudo systemctl start containerd
```

## 环境变量配置

可以通过 `CONTAINERD_DEFAULT_IMAGE_REGISTRY` 环境变量设置默认镜像仓库：

```bash
export CONTAINERD_DEFAULT_IMAGE_REGISTRY=registry.example.com
```

## 故障排除

### 1. 构建失败
- 检查 Go 版本兼容性
- 确认所有依赖已安装
- 查看详细错误日志

### 2. 架构不支持
- 确认目标架构在支持列表中
- 检查 QEMU 设置是否正确

### 3. 性能优化
- 启用 ccache 缓存
- 使用并行构建
- 优化 Docker 镜像

## 自定义配置

可以通过修改 `.github/workflows/build-multiarch.yml` 来自定义：

- 添加新的架构支持
- 修改构建参数
- 调整触发条件
- 自定义包结构

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个工作流！