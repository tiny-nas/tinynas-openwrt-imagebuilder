#!/usr/bin/env bash
# 把 main 上的公共文件同步到所有 arch/<name> 分支
# 背景：arch 分支是 main 的快照，main 上 common/ 或 workflows 的修复
# 不会自动传播到已 fork 的分支，需要用本脚本批量覆盖同步。
#
# 同步范围（文件级覆盖，无合并冲突）：
#   common/build-template.sh      ← 打包模板（zstd 修复等）
#   common/packages.common.txt    ← 通用包列表
#   common/CHANGELOG.md
#   README.md / CONTRIBUTING.md
#   scripts/gen-arch-branch.sh
#   .github/workflows/build.yml / lint.yml
#
# 不同步：.gitignore（分支需要自己不含 /arch/ 的版本）、arch/<name>/（各分支专属）
#
# 用法：sudo/普通用户均可  ./scripts/sync-common-to-branches.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

SYNC_FILES=(
    common/build-template.sh
    common/packages.common.txt
    common/packages.tier-pro.txt
    common/packages.tier-edge.txt
    common/packages.tier-lite.txt
    common/CHANGELOG.md
    README.md
    CONTRIBUTING.md
    scripts/gen-arch-branch.sh
    .github/workflows/build.yml
    .github/workflows/lint.yml
)

git fetch origin --prune --quiet
BRANCHES=$(git ls-remote --heads origin "refs/heads/arch/*" | awk '{print $2}' | sed 's|refs/heads/||' | sort)

TOTAL=$(echo "${BRANCHES}" | grep -c . || true)
echo "=== 待同步分支数: ${TOTAL} ==="

OK=0; SKIP=0; FAIL=0; FAILED_LIST=()
i=0
for b in ${BRANCHES}; do
    i=$((i+1))
    git checkout -B "${b}" "origin/${b}" --quiet 2>/dev/null || {
        echo "[$i/$TOTAL] ❌ $b: checkout 失败"; FAIL=$((FAIL+1)); FAILED_LIST+=("$b"); continue
    }
    # 文件级覆盖（分支上一定已有这些文件，checkout main -- 直接覆盖）
    git checkout main -- "${SYNC_FILES[@]}" 2>/dev/null
    # 分支专属文件（arch/<name>/）的历史品牌字修正（简盒→锦盒）
    BRAND_FILES=$(grep -rl "简盒" arch/ 2>/dev/null || true)
    if [ -n "${BRAND_FILES}" ]; then
        perl -pi -e 's/简盒/锦盒/g' ${BRAND_FILES}
        git add -f arch/
    fi
    if git diff --cached --quiet; then
        SKIP=$((SKIP+1))
        echo "[$i/$TOTAL] ⏭️  $b: 已是最新，跳过"
    else
        if git -c commit.gpgsign=false commit -m "sync: 从 main 同步公共文件（zstd 修复 + CI 动态分支解析）

同步范围：common/build-template.sh（.tar.zst 适配）、packages.common.txt、
CHANGELOG、README、CONTRIBUTING、gen-arch-branch.sh（git add -f 修复）、
workflows（build.yml 动态解析分支名 + zstd 依赖、lint.yml 覆盖 arch/**）" --quiet; then
            if git push origin "${b}" --quiet 2>&1; then
                OK=$((OK+1))
                echo "[$i/$TOTAL] ✅ $b: 已同步并 push"
            else
                FAIL=$((FAIL+1)); FAILED_LIST+=("$b")
                echo "[$i/$TOTAL] ❌ $b: push 失败"
            fi
        else
            FAIL=$((FAIL+1)); FAILED_LIST+=("$b")
            echo "[$i/$TOTAL] ❌ $b: commit 失败"
        fi
    fi
done

git checkout main --quiet
echo ""
echo "=== 同步完成：成功 ${OK}，跳过 ${SKIP}，失败 ${FAIL} ==="
[ ${#FAILED_LIST[@]} -gt 0 ] && printf '失败分支: %s\n' "${FAILED_LIST[*]}"
exit 0