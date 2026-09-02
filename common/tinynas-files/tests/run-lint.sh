#!/bin/sh
# run-lint.sh — 覆盖层总门禁（8 条军规静态化 + 宿主行为测试）
# 在仓库任意目录可执行；全绿退出 0
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT="$HERE/.."
cd "$ROOT" || exit 1
FAIL=0
pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; FAIL=1; }

echo "── 1. shell 语法（sh -n 全量）──"
SYNTAX_OK=1
while IFS= read -r f; do
    [ -f "$f" ] || continue
    sh -n "$f" 2>/dev/null || { echo "  ❌ 语法错误: $f"; SYNTAX_OK=0; FAIL=1; }
done <<EOF
$(find etc usr www -type f \( -name '*.sh' -o -perm -u+x \) 2>/dev/null)
EOF
[ "$SYNTAX_OK" -eq 1 ] && pass "全部 shell 文件语法通过"

echo "── 2. 军规①②：init.d rc.common shebang + START= + 禁手放 rc.d ──"
for f in etc/init.d/*; do
    [ -f "$f" ] || continue
    head -1 "$f" | grep -q '/etc/rc\.common' && grep -q '^START=' "$f" && pass "$f" || fail "$f (shebang/START)"
done
[ -d etc/rc.d ] && fail "存在 etc/rc.d/（禁止）" || pass "无手放 rc.d/"

echo "── 3. 军规③：uci-defaults 幂等 exit 0 ──"
for f in etc/uci-defaults/*; do
    [ -f "$f" ] || continue
    tail -1 "$f" | grep -q '^exit 0$' && pass "$f" || fail "$f (结尾须 exit 0)"
done

echo "── 4. 军规④：CGI 可执行 + 非 luci 前缀 + 禁 eval ──"
for f in www/cgi-bin/*; do
    [ -f "$f" ] || continue
    [ -x "$f" ] || fail "$f 缺 +x"
    case "$(basename "$f")" in luci*) fail "$f 占用 luci 前缀";; *) :;; esac
    grep -q 'eval' "$f" && fail "$f 含 eval" || pass "$f"
done

echo "── 5. 军规⑤：hotplug 序号 >10 且不挂载 ──"
for f in etc/hotplug.d/block/*; do
    [ -f "$f" ] || continue
    n=$(basename "$f" | cut -d- -f1)
    [ "$n" -gt 10 ] 2>/dev/null && pass "$f (序号 $n)" || fail "$f 序号须 >10"
    grep -v '^[[:space:]]*#' "$f" | grep -qE '(^|[/[:space:]])mount([[:space:]]|$)' \
        && fail "$f 疑似执行挂载（与 10-mount 竞争）" || pass "$f 无挂载动作"
done

echo "── 6. 军规⑦：前端零外链 + 向导体积预算 ──"
if grep -rqE '(src|href)="https?://' www/ 2>/dev/null; then
    fail "外链: $(grep -rlE '(src|href)="https?://' www/)"
else
    pass "零公网外链"
fi
WZ=$(wc -c < www/tinynas-wizard.html 2>/dev/null || echo 999999)
[ "$WZ" -le 51200 ] && pass "wizard ${WZ}B ≤ 51200B" || fail "wizard ${WZ}B 超预算"

echo "── 7. 军规⑧：无 .gitkeep / 无 ED25519 私钥入库 ──"
find . -name '.gitkeep' | grep -q . && fail "残留 .gitkeep" || pass "无 .gitkeep"
# tests/fixtures/keys/ 下的 *test-priv* 为有意入库的测试密钥（公开放置，不具任何生产权限）
LEAK=$(find . \( -name '*priv*' -o -name '*secret*' -o -name '*salt*' \) -type f | grep -v 'tests/fixtures/keys/ed25519-test-priv')
[ -n "$LEAK" ] && fail "疑似私钥/盐值入库: $LEAK" || pass "无私钥入库（仅测试密钥）"

echo "── 8. 行为测试 ──"
"$HERE/test-machine-id.sh"      || FAIL=1
"$HERE/test-license-import.sh"  || FAIL=1
export TINYNAS_SYSINFO_ROOT="$HERE/fixtures/sysinfo" TINYNAS_MACHINE_ID="$ROOT/usr/bin/tinynas-machine-id" TINYNAS_SHARE_ROOT="$HERE/fixtures/share"
www/cgi-bin/machine-id | tail -1 | grep -q '"display_machine_id":"40F6598739D3B481"' && pass "CGI machine-id 行为" || fail "CGI machine-id"
www/cgi-bin/status | sed '1,2d' | python3 -m json.tool >/dev/null 2>&1 && pass "CGI status 合法 JSON" || fail "CGI status"
QUERY_STRING='path=/Movies' www/cgi-bin/files | sed '1,2d' | grep -q '"a.mp4"' && pass "CGI files 列表" || fail "CGI files"
QUERY_STRING='path=/../etc' www/cgi-bin/files | sed '1,2d' | grep -q forbidden && pass "CGI files 穿越防护" || fail "穿越防护失效"

echo "════════════════════════════"
if [ "$FAIL" -eq 0 ]; then echo "✅ 全部门禁通过"; else echo "❌ 存在失败项"; fi
exit $FAIL
