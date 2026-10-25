# dsh-three-kingdoms

开着就等——**一进游戏，它自己放《关羽之歌》，屏幕上浮出四行字**。

没有按钮，没有面板，不抢键鼠，不截屏。装一次，开机自启。

## 它怎么认游戏

三层，任意一层命中就算：

1. **进程名**：minecraft / hoi4 / stellaris / ck3 / eu4 / game.exe / evelauncher / exefile …
2. **窗口标题**：Red Alert 2 / 星战前夜 / Hearts of Iron IV / Total War / 三国 …
3. **独占全屏**：`QUNS_RUNNING_D3D_FULL_SCREEN`，认不出的游戏也跑不掉。

后台窗口也算，不用切到前台。同一个游戏只触发一次，换游戏才会再来。

## 命中之后

- 本地 mp3（`media/guanyu.mp3`，81 秒）静默播放，不依赖网易云客户端；已经在放就不叠加。
- 屏幕上方浮一块字，40px，鼠标穿透，14 秒自己消失：

```
胜    兵    必     骄
必                    兵
兵                    必
哀    必    兵     败
```

## 装

```powershell
git clone https://github.com/pairun325/dsh-three-kingdoms.git
cd dsh-three-kingdoms
powershell -ExecutionPolicy Bypass -File install.ps1
```

`install.ps1` 会做两件事：缺音频就按网易云外链下一次；把 `helper/watch.ps1` 注册成开机自启的计划任务 `dsh-game-music`，并立刻启动。

卸载：

```powershell
Unregister-ScheduledTask -TaskName dsh-game-music -Confirm:$false
```

## 作为 DSH 插件用（可选）

profile 的 `package.json` 里加：

```json
"dependencies": { "dsh-three-kingdoms": "link:E:/path/to/dsh-three-kingdoms" },
"dsh": { "profile": { "bundles": [ ..., "dsh-three-kingdoms" ] } }
```

就有 `three_kingdoms_play` 工具和 `POST /three-kingdoms/play` 路由，能手动放一次。

## 文件

| 文件 | 干什么 |
| --- | --- |
| `helper/watch.ps1` | 每 2 秒扫一次，认游戏、去重、派活 |
| `helper/play.ps1` | 放本地 mp3（有单例检查） |
| `helper/play-local.ps1` | WPF MediaPlayer 无窗口播放 |
| `helper/show-art.ps1` | 浮四行字，鼠标穿透，自动消失 |
| `lib/index.js` | 可选：DSH 工具 + HTTP 路由 |

日志：`%TEMP%\dsh-three-kingdoms\watch.log`、`play.log`。

## 环境

- Windows 10/11 + PowerShell 5.1
- 音频版权归原方（《关羽之歌》，专辑 Three Kingdoms，赵季平），仓库不带音频文件

## License

MIT
