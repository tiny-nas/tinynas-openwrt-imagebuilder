# 贡献指南

## 新增架构分支

1. 从 `main` 创建分支 `arch/<arch-name>`（如 `arch/ramips-mt7621`、`ath79-generic`）
2. 在 `arch/<arch-name>/` 下创建：
   - `build.sh` —— 调用 `../../common/build-template.sh`，传入 `OPENWRT_TARGET_DIR` 和 `PROFILE`
   - `packages.txt` —— 继承 `../../common/packages.common.txt` + 架构专属包
   - `profiles/<profile-name>.txt` —— Image Builder PROFILE 名
   - `README.md` —— 该架构的硬件说明、刷机 SOP、已验证机型
3. 修改 `README.md` "当前支持的架构" 表格，加一行
4. 提交并 push `arch/<arch-name>`，GitHub Actions 自动跑打包验证

## 修改通用模板/覆盖层

1. 从 `main` 创建分支 `feature/<name>`
2. 修改 `common/` 下文件（**不要在 `arch/` 下改**通用内容）
3. push 后跑 lint；merge 后 CI 会自动对所有 `arch/**` 分支触发回归构建

## 修改架构专属内容

1. 从对应 `arch/<name>` 创建分支
2. 修改 `arch/<name>/` 下文件
3. push 后 CI 跑该架构打包验证

## 提交信息规范（建议）

- `feat(common): 新增可视化品牌资源` —— `common/` 改动
- `feat(arch/x86_64): 增加 lenovo-mini-pc profile` —— 架构分支改动
- `fix(build-template): 修复 Image Builder 路径解析` —— 模板 bug
- `docs: 更新 README 支持架构列表` —— 文档

## Code Review

- 任何 `common/` 的改动会同时影响所有架构分支，**必须**经架构维护者 review
- `arch/` 下的改动由对应架构维护者 review
- `tinynas-files/` 是品牌核心，**必须**经项目负责人 review