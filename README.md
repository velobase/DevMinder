# velobase-PM

[![GitHub stars](https://img.shields.io/github/stars/velobase/velobase-process-manager?style=social)](https://github.com/velobase/velobase-process-manager/stargazers)
[![Build macOS DMG](https://github.com/velobase/velobase-process-manager/actions/workflows/build-dmg.yml/badge.svg)](https://github.com/velobase/velobase-process-manager/actions/workflows/build-dmg.yml)
[![Latest release](https://img.shields.io/github/v/release/velobase/velobase-process-manager?label=release)](https://github.com/velobase/velobase-process-manager/releases/latest)
[![Download DMG](https://img.shields.io/badge/download-DMG-2f6feb)](https://github.com/velobase/velobase-process-manager/releases/latest/download/velobase-PM.dmg)

一个轻量的 macOS 菜单栏小工具，用来发现开发时遗留的端口监听进程和指定命令进程，并在需要时手动终止它们。

[下载最新版 DMG](https://github.com/velobase/velobase-process-manager/releases/latest/download/velobase-PM.dmg) ·
[查看 Releases](https://github.com/velobase/velobase-process-manager/releases) ·
[报告问题](https://github.com/velobase/velobase-process-manager/issues)

## 为什么做它

开发项目时，Vite、Next、Flask、Redis、Postgres、Docker 容器这些进程偶尔会留在后台。等你再启动新项目时，端口被占用、进程忘记关、Docker 映射端口看起来像系统进程，都挺烦。

velobase-PM 做的事很简单：在菜单栏里安静地看着常用开发端口和你配置的进程规则，发现目标后展示出来，终止动作始终由你手动触发。

## 功能

- 菜单栏常驻：不占 Dock，不自动弹桌面窗口。
- 端口监听：默认覆盖 Next/React/Nuxt、Vite、Angular、Astro、Flask/API、Postgres、Redis、Storybook、Django/FastAPI、Spring/Tomcat/API、Wrangler 等常用开发端口。
- 主动识别：用关键词或 `/regex/` 规则匹配全局进程列表，适合识别 `vite`、`next dev`、`rails server`、`uvicorn` 等命令。
- 手动休眠：一键暂停或恢复扫描，默认每 30 秒扫描一次。
- 安全终止：默认发送 `TERM`，进程未退出时再提供 `KILL`。
- Docker 适配：Docker Desktop 映射端口会解析到容器并执行 `docker stop` / `docker kill`，不会直接终止 Docker 后端进程。
- 系统进程保护：Apple 系统进程会标记为系统进程，不提供终止按钮。
- 空闲端口折叠：运行中的端口优先展示，空闲端口可折叠。
- 国际化和外观：支持跟随系统、中文、English；支持跟随系统、浅色、深色。

## 安装

1. 下载 [velobase-PM.dmg](https://github.com/velobase/velobase-process-manager/releases/latest/download/velobase-PM.dmg)。
2. 打开 DMG，把 `velobase-PM.app` 拖到 `Applications`。
3. 启动后查看 macOS 菜单栏图标。

当前免费分发版没有 Apple Developer ID 公证。如果 macOS 提示无法验证开发者，可以在 **系统设置 -> 隐私与安全性** 里选择 **仍要打开**。这不是最理想的分发体验，但可以避免为了开源小工具额外支付 Apple Developer Program 费用。

## 使用

- 点击菜单栏图标查看命中的端口进程和规则进程。
- 点击刷新按钮立即扫描。
- 点击暂停按钮进入休眠态，停止后台定时扫描。
- 点击进程右上角的关闭按钮会先发送 `TERM`。
- 如果进程没有退出，按钮会切换为强制停止。
- Docker 容器会显示容器名，停止动作会作用在容器上。
- Apple 系统进程会显示系统标识，不允许直接终止。

## 开发

```bash
swift run ProcessManager
```

## 检查

```bash
swift run ProcessManagerCheck
```

## 本地打包

打包 `.app`：

```bash
./scripts/build-app.sh
open dist/velobase-PM.app
```

打包 `.dmg`：

```bash
./scripts/build-dmg.sh
open dist/velobase-PM-0.1.1.dmg
```

可以通过环境变量指定版本和文件名：

```bash
APP_VERSION=0.1.2 BUILD_NUMBER=3 DMG_NAME=velobase-PM-0.1.2.dmg ./scripts/build-dmg.sh
```

## 自动发布

GitHub Actions 会在以下场景自动构建 DMG：

- push 到 `main`：编译、检查、打包，并上传 Actions artifact。
- pull request：编译、检查、打包 artifact。
- push `v*` tag：创建 GitHub Release，并上传两个 DMG 附件。

发布新版本：

```bash
git tag v0.1.2
git push origin v0.1.2
```

Release 会包含：

- `velobase-PM-0.1.2.dmg`：带版本号的归档文件。
- `velobase-PM.dmg`：固定文件名，用于 README 和网站的最新版下载链接。

稳定下载链接：

```text
https://github.com/velobase/velobase-process-manager/releases/latest/download/velobase-PM.dmg
```

## License

[MIT](LICENSE)
