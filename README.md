# velobase-PM

一个 macOS 菜单栏工具，用来发现开发时遗留的端口监听进程和指定命令进程，并手动终止它们。

## 功能

- 被动监测端口：默认覆盖 Next/React/Nuxt、Vite、Angular、Astro、Flask/API、Postgres、Redis、Storybook、Django/FastAPI、Spring/Tomcat/API、Wrangler 等常用开发端口。
- 主动识别进程：用关键词或 `/regex/` 规则匹配全局进程列表，默认覆盖常见前端、Node、Python、Rails、Spring Boot 等开发命令。
- 手动休眠：菜单栏一键暂停或恢复扫描。
- 手动终止：对命中的进程发送 `TERM`，必要时可使用 `KILL`。
- Docker 适配：Docker Desktop 映射端口会解析到容器并执行 `docker stop` / `docker kill`，不会直接终止 Docker 后端进程。
- 空闲端口折叠：运行中的端口优先展示，空闲端口默认收起，点击可展开。
- 语言：支持跟随系统、中文、English。
- 外观：支持跟随系统、浅色、深色。
- 图标：打包时生成本地 `.icns`，用于 Dock、Command-Tab 和 Finder 展示。
- 本地配置：端口、规则和扫描间隔保存在 macOS `UserDefaults`，默认每 30 秒扫描一次。

## 开发运行

```bash
swift run ProcessManager
```

## 冒烟检查

```bash
swift run ProcessManagerCheck
```

## 打包为 app

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open dist/velobase-PM.app
```

应用是菜单栏常驻形式，启动后看 macOS 菜单栏图标。
当前版本也会打开一个普通窗口，并出现在 Dock 中；如果关闭窗口，点击 Dock 图标可以重新打开。

## 规则说明

- 普通文本会对可执行文件路径和完整命令行做大小写不敏感匹配。
- 以 `/` 包起来的内容会按正则表达式匹配，例如 `/node .*vite/`。
- 工具不会自动杀进程，所有终止动作都需要手动点击。
