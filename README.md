# 打小人 Da Siu Yan — iOS App

一款以中国传统民俗「打小人」为主题的全屏极简悬浮弥散风 iOS 应用。

---

## 一、用 Codemagic 打包 IPA（不需要 Mac）

这是**推荐路径**：把代码推到 GitHub → Codemagic 云端打包 → 下载 IPA → 侧载到 iPad。

### 步骤 1：把项目推到 GitHub

在 Windows 上（本地已装 git）：

```bash
cd d:\打小人
git init
git add .
git commit -m "Initial commit"
git branch -M main
# 去 github.com 创建一个新仓库（可以是 private），然后：
git remote add origin https://github.com/你的用户名/da-siu-yan.git
git push -u origin main
```

### 步骤 2：在 Codemagic 配置构建

1. 注册 [codemagic.io](https://codemagic.io)（用 GitHub 账号登录最方便）
2. 点击 **Add application** → 选择你刚刚推送的仓库 → 选 **iOS App**
3. Codemagic 会自动识别项目根目录的 `codemagic.yaml`
4. 打开 `codemagic.yaml`，把里面 `your@email.com` 替换为你的邮箱
5. 在 Codemagic 控制台右上角选择工作流 **unsigned-ipa**，点击 **Start new build**

构建约 8–15 分钟。成功后你会在邮箱里收到下载链接，或直接在 Codemagic **Artifacts** 标签下载 `DaSiuYan-unsigned.ipa`。

### 步骤 3：侧载 IPA 到 iPad（免费 Apple ID 即可）

**方案 A：Sideloadly（最简单，推荐）**
1. 在 Windows/Mac 下载 [Sideloadly](https://sideloadly.io)
2. 用 USB 连接 iPad，解锁设备
3. 把下载好的 `DaSiuYan-unsigned.ipa` 拖进 Sideloadly
4. 填入你的 Apple ID + App-Specific Password（在 appleid.apple.com 生成）
5. 点击 Start → 等待完成
6. 在 iPad **设置 → 通用 → VPN 与设备管理** 中信任该证书
7. 打开即可使用（免费账号签名有效期 7 天，到期用 Sideloadly 重新签名即可）

**方案 B：AltStore（免电脑重签，推荐长期使用）**
1. Mac/Windows 安装 [AltServer](https://altstore.io)
2. 首次用电脑把 AltStore 装到 iPad
3. 之后把 IPA 发到 iPad（AirDrop/云盘），用 AltStore 打开 → 安装
4. AltStore 会在同一 Wi-Fi 下**后台自动续签**

**方案 C：爱思助手（国内用户，简单但需电脑）**
1. 下载 [爱思助手](https://www.i4.cn)
2. USB 连接 iPad → 打开 IPA → 填 Apple ID

---

## 二、在 Mac 上本地构建（可选）

如果你有 Mac：

```bash
brew install xcodegen
cd DaSiuYan
xcodegen generate
open DaSiuYan.xcodeproj
```

在 Xcode 中选择目标模拟器或真机，按 ⌘R 运行。

### 真机测试注意

- Core Haptics 仅在 iPhone 8+ 真机生效（模拟器无震动）
- AVSpeechSynthesizer 首次使用 zh-HK 粤语需系统下载语音包：
  **设置 → 辅助功能 → 朗读内容 → 声音 → 中文（香港）→ 下载**
- RealityKit 3D 效果需 A12+ 芯片（本 Demo 暂用 SpriteKit 2D 火焰）

---

## 三、已实现功能（完整一期）

### 核心流程
- ✅ 全屏极简悬浮弥散风 UI（5 套预设配色）
- ✅ 首页纸片人卡片列表（长按删除、10 存档上限）
- ✅ **相册导入 + Vision 人像检测 + Core Image 纸扎风格化**
- ✅ 打击场景：6 部位分层命中 + 6 种道具切换
- ✅ SpriteKit 粒子反馈（碎纸 + 尘土）
- ✅ 分部位动画（头摇、肢体挥动、躯干撕裂）
- ✅ Damage_State 0-100 + 裂痕叠加 + 整体暗化
- ✅ AVSpeechSynthesizer 咒语（粤语/普通话双版本）
- ✅ Core Haptics 按道具强度映射（含降级链）
- ✅ 焚化仪式：拖拽 + 火焰动画 + 灰烬飘散
- ✅ Blessing 生成（P(圣筊) ≥ 85%）
- ✅ 完成总结页

### 数据层
- ✅ **Core Data 持久化**（纸片人、焚化记录、自定义咒语）
- ✅ 沙盒图片文件管理
- ✅ 可选 iCloud 同步（私有库）
- ✅ 焚化历史记录列表 + 详情 + 删除

### UI/UX
- ✅ Floating HUD 5 秒闲置自动淡化至 30%（触碰/打击恢复）
- ✅ 深色/浅色/跟随系统三模式
- ✅ 5 套预设弥散配色
- ✅ iPhone + iPad 自适应

### 辅助功能
- ✅ 自定义咒语编辑器（最多 20 条）
- ✅ 传统知识 Tab（4 个子条目：习俗/地区/历史/禁忌）
- ✅ 首启文化声明
- ✅ 隐私提示（首次使用照片导入）
- ✅ 设置页全量持久化
- ✅ 清除全部数据（二次确认）

---

## 四、项目结构

```
打小人/
├─ codemagic.yaml                 ← Codemagic CI 配置（两套 workflow）
├─ README.md
└─ DaSiuYan/
   ├─ project.yml                 ← XcodeGen 配置
   ├─ App/                        入口 + 依赖注入
   ├─ Features/
   │  ├─ Home/                    首页
   │  ├─ CreateEffigy/            纸片人创建 + 文化声明
   │  ├─ Strike/                  打击主场景
   │  ├─ Cremation/               焚化 + 历史
   │  ├─ Summary/                 完成总结
   │  ├─ Knowledge/               传统知识
   │  ├─ Settings/                设置 + 自定义咒语
   │  └─ HUD/                     悬浮淡化状态机
   ├─ Services/
   │  ├─ Storage/                 Core Data + 图片文件
   │  ├─ Settings/                UserDefaults 偏好
   │  ├─ PaperEffigy/             纸片人管理
   │  ├─ Image/                   Vision + Core Image
   │  ├─ Photo/                   PhotosPicker 封装
   │  ├─ Prop/                    道具系统
   │  ├─ Audio/                   AVFoundation + Speech
   │  ├─ Haptic/                  Core Haptics
   │  ├─ Incantation/             咒语系统
   │  ├─ VisualFeedback/          SpriteKit 粒子
   │  ├─ Background/              弥散背景
   │  └─ Render/                  渲染分级
   ├─ Components/                 可复用 UI
   ├─ Models/
   │  ├─ *.swift                  领域值类型
   │  └─ CoreData/                .xcdatamodeld
   ├─ Resources/                  Info.plist + Assets
   └─ Tests/                      核心逻辑 smoke tests
```

---

## 五、Spec 文档

- `.kiro/specs/da-siu-yan-app/requirements.md` — 18 条 EARS 需求
- `.kiro/specs/da-siu-yan-app/design.md` — 架构 + 18 条 Correctness Properties
- `.kiro/specs/da-siu-yan-app/tasks.md` — 实现任务清单

## 六、合规声明

本应用仅供娱乐与文化体验用途，所有数据仅保存在本机或用户自有 iCloud。
不向任何第三方服务器上传照片、元数据或用户识别信息。
