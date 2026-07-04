#!/usr/bin/env bash
#
# test-subagent-models.sh — validate that every model used by the
# .codex/agents/*.toml subagents is reachable through its configured
# provider.
#
# All 22 subagents set model_provider = "fcc".  The fcc proxy
# (fcc-server at 127.0.0.1:8082) is a universal proxy that serves
# both opencode_go models and OpenAI models.  OpenAI models are also
# tested through the built-in openai provider as a fallback check.
#
# Each test sends a trivial prompt and checks for "TESTOK" in the
# response.  The script exits 0 when every test passes.
#
# Usage:
#   bash scripts/test-subagent-models.sh
#
# Requirements:
#   - codex CLI on PATH
#   - fcc-server running at 127.0.0.1:8082  (start with: fcc-server)
#   - FCC_CODEX_API_KEY env var set
#   - ~/.codex/config.toml contains [model_providers.fcc] section
#   - ~/.codex/auth.json present (for openai-provider tests)

set -u

RESULTS_DIR="/tmp/subagent-test-results"
mkdir -p "$RESULTS_DIR"
rm -f "$RESULTS_DIR"/*.txt "$RESULTS_DIR"/*.log 2>/dev/null

TIMEOUT=120
PROMPT="Reply with exactly the word TESTOK and nothing else. Do not use any tools."

PASS=0
FAIL=0
declare -a SUMMARY

# run_test <label> <provider> <model> <effort>
run_test() {
  local label="$1" provider="$2" model="$3" effort="$4"
  local outfile="$RESULTS_DIR/${label}.txt"
  local logfile="$RESULTS_DIR/${label}.log"
  local extra_config=""

  [ "$provider" = "fcc" ] && extra_config="-c model_provider=fcc"

  printf "  %-50s " "$label"

  timeout "$TIMEOUT" codex exec \
    --skip-git-repo-check \
    --ephemeral \
    -s read-only \
    -c model_reasoning_effort="$effort" \
    $extra_config \
    -m "$model" \
    -o "$outfile" \
    "$PROMPT" \
    > "$logfile" 2>&1
  local rc=$?

  if [ $rc -ne 0 ]; then
    printf "FAIL (exit %d)\n" "$rc"
    SUMMARY+=("FAIL|$label|$provider|$model|$effort|exit $rc")
    FAIL=$((FAIL + 1))
    return
  fi

  local resp
  resp="$(cat "$outfile" 2>/dev/null)"
  if echo "$resp" | grep -qi "TESTOK"; then
    printf "PASS\n"
    SUMMARY+=("PASS|$label|$provider|$model|$effort|ok")
    PASS=$((PASS + 1))
  else
    printf "FAIL (no TESTOK)\n"
    SUMMARY+=("FAIL|$label|$provider|$model|$effort|no TESTOK in response")
    FAIL=$((FAIL + 1))
  fi
}

echo "================================================================"
echo "  Subagent model validation — $(date '+%Y-%m-%d %H:%M')"
echo "  fcc-server: 127.0.0.1:8082"
echo "================================================================"

echo ""
echo "-- opencode_go models via fcc (medium effort) --"
run_test "deepseek-v4-pro_fcc_medium"    "fcc" "opencode_go/deepseek-v4-pro"    "medium"
run_test "deepseek-v4-flash_fcc_medium" "fcc" "opencode_go/deepseek-v4-flash"  "medium"
run_test "minimax-m3_fcc_medium"        "fcc" "opencode_go/minimax-m3"         "medium"
run_test "glm-5.2_fcc_medium"           "fcc" "opencode_go/glm-5.2"            "medium"

echo ""
echo "-- OpenAI models via fcc (medium effort) --"
run_test "gpt-5.4-mini_fcc_medium"  "fcc" "gpt-5.4-mini"  "medium"
run_test "gpt-5.4_fcc_medium"       "fcc" "gpt-5.4"       "medium"
run_test "gpt-5.5_fcc_medium"       "fcc" "gpt-5.5"       "medium"

echo ""
echo "-- OpenAI models via openai (medium effort) --"
run_test "gpt-5.4-mini_openai_medium"  "openai" "gpt-5.4-mini"  "medium"
run_test "gpt-5.4_openai_medium"       "openai" "gpt-5.4"       "medium"
run_test "gpt-5.5_openai_medium"       "openai" "gpt-5.5"       "medium"

echo ""
echo "-- high-effort spot checks via fcc --"
run_test "minimax-m3_fcc_high"  "fcc" "opencode_go/minimax-m3"  "high"
run_test "gpt-5.4_fcc_high"     "fcc" "gpt-5.4"                 "high"

# ── summary ─────────────────────────────────────────────────────────
echo ""
echo "================================================================"
echo "  SUMMARY:  $PASS passed,  $FAIL failed  (of $((PASS + FAIL)) tests)"
echo "================================================================"
echo ""
printf "  %-6s %-38s %-8s %-28s %-7s %s\n" "STAT" "LABEL" "PROV" "MODEL" "EFFORT" "DETAIL"
printf "  %s\n" "------------------------------------------------------------------------------------------"
for line in "${SUMMARY[@]}"; do
  IFS='|' read -r stat label provider model effort detail <<< "$line"
  printf "  %-6s %-38s %-8s %-28s %-7s %s\n" "$stat" "$label" "$provider" "$model" "$effort" "$detail"
done
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS GREEN"
  exit 0
else
  echo "$FAIL TEST(S) FAILED — see $RESULTS_DIR/*.log for details"
  exit 1
fi
