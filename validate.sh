#!/usr/bin/env bash
#
# Structural validation for the TDD skill.
# Checks internal links, JSON validity, numbering, and cross-references.
#
# Usage: ./validate.sh
# Exit code: 0 = all checks pass, 1 = failures found

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PASS=0
FAIL=0
ERRORS=()

pass() {
    PASS=$((PASS + 1))
    printf "  \033[32mPASS\033[0m %s\n" "$1"
}

fail() {
    FAIL=$((FAIL + 1))
    ERRORS+=("$1")
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
}

section() {
    printf "\n\033[1m%s\033[0m\n" "$1"
}

# ─────────────────────────────────────────────
section "1. Required files exist"
# ─────────────────────────────────────────────

required_files=(
    "SKILL.md"
    "PROJECT.md"
    "README.md"
    "LICENSE"
    "references/chunk-template.md"
    "references/tracker-schema.md"
    "references/quality-checklist.md"
)

for f in "${required_files[@]}"; do
    if [[ -f "$f" ]]; then
        pass "$f exists"
    else
        fail "$f is missing"
    fi
done

# ─────────────────────────────────────────────
section "2. Internal markdown links resolve"
# ─────────────────────────────────────────────

check_links_in() {
    local file="$1"
    local dir
    dir="$(dirname "$file")"

    local targets
    targets="$(grep -oP '\[.*?\]\(\K[^)]+\.md\b[^)]*' "$file" 2>/dev/null || true)"

    if [[ -z "$targets" ]]; then
        return
    fi

    while IFS= read -r target; do
        # Strip any anchor (#section)
        target="${target%%#*}"
        local resolved="$dir/$target"
        if [[ -f "$resolved" ]]; then
            pass "$file -> $target"
        else
            fail "$file -> $target (not found: $resolved)"
        fi
    done <<< "$targets"
}

check_links_in "SKILL.md"
check_links_in "README.md"
check_links_in "references/chunk-template.md"
check_links_in "references/tracker-schema.md"
check_links_in "references/quality-checklist.md"

# ─────────────────────────────────────────────
section "3. JSON examples are valid"
# ─────────────────────────────────────────────

validate_json_blocks() {
    local file="$1"
    local block_num=0
    local in_json=false
    local json_buf=""

    while IFS= read -r line; do
        if [[ "$line" == '```json' ]]; then
            in_json=true
            json_buf=""
            block_num=$((block_num + 1))
            continue
        fi
        if [[ "$line" == '```' ]] && $in_json; then
            in_json=false
            if echo "$json_buf" | python3 -m json.tool > /dev/null 2>&1; then
                pass "$file JSON block #$block_num is valid"
            else
                fail "$file JSON block #$block_num is invalid JSON"
            fi
            continue
        fi
        if $in_json; then
            json_buf+="$line"$'\n'
        fi
    done < "$file"
}

validate_json_blocks "references/tracker-schema.md"
validate_json_blocks "references/chunk-template.md"

# ─────────────────────────────────────────────
section "4. Quality checklist has exactly 8 points"
# ─────────────────────────────────────────────

checklist_count="$(grep -cP '^## \d+\.' references/quality-checklist.md || true)"
if [[ "$checklist_count" -eq 8 ]]; then
    pass "quality-checklist.md has $checklist_count points"
else
    fail "quality-checklist.md has $checklist_count points (expected 8)"
fi

# Verify sequential numbering 1-8
expected=1
checklist_nums="$(grep -oP '^## \K\d+' references/quality-checklist.md || true)"
while IFS= read -r num; do
    [[ -z "$num" ]] && continue
    if [[ "$num" -eq "$expected" ]]; then
        pass "Checklist point $num is sequential"
    else
        fail "Checklist point $num out of order (expected $expected)"
    fi
    expected=$((expected + 1))
done <<< "$checklist_nums"

# ─────────────────────────────────────────────
section "5. SKILL.md phases are sequential (1-6)"
# ─────────────────────────────────────────────

phase_count="$(grep -cP '^## Phase \d+:' SKILL.md || true)"
if [[ "$phase_count" -eq 6 ]]; then
    pass "SKILL.md has $phase_count phases"
else
    fail "SKILL.md has $phase_count phases (expected 6)"
fi

expected=1
phase_nums="$(grep -oP '^## Phase \K\d+' SKILL.md || true)"
while IFS= read -r num; do
    [[ -z "$num" ]] && continue
    if [[ "$num" -eq "$expected" ]]; then
        pass "Phase $num is sequential"
    else
        fail "Phase $num out of order (expected $expected)"
    fi
    expected=$((expected + 1))
done <<< "$phase_nums"

# ─────────────────────────────────────────────
section "6. Lessons learned are sequentially numbered"
# ─────────────────────────────────────────────

# Extract lesson numbers only from the "Lessons Learned" section
# (between "## Lessons Learned" and the next "---" or "## " heading)
lesson_nums=()
in_lessons=false
while IFS= read -r line; do
    if [[ "$line" == "## Lessons Learned"* ]]; then
        in_lessons=true
        continue
    fi
    if $in_lessons && [[ "$line" == "---" || "$line" == "## "* ]]; then
        break
    fi
    if $in_lessons; then
        num="$(echo "$line" | grep -oP '^\d+(?=\. \*\*)' || true)"
        if [[ -n "$num" ]]; then
            lesson_nums+=("$num")
        fi
    fi
done < SKILL.md

lesson_count=${#lesson_nums[@]}
if [[ "$lesson_count" -gt 0 ]]; then
    pass "Found $lesson_count lessons"
else
    fail "No lessons found in SKILL.md"
fi

expected=1
for num in "${lesson_nums[@]}"; do
    if [[ "$num" -eq "$expected" ]]; then
        pass "Lesson $num is sequential"
    else
        fail "Lesson $num out of order (expected $expected)"
    fi
    expected=$((expected + 1))
done

# ─────────────────────────────────────────────
section "7. SKILL.md 8-point summaries match checklist"
# ─────────────────────────────────────────────

checklist_names=(
    "Completeness"
    "Correctness"
    "Gaps (Functional)"
    "Standards"
    "Regression"
    "Robustness"
    "Gaps (Architectural)"
    "Blindspots"
)

for name in "${checklist_names[@]}"; do
    count="$(grep -c "\*\*$name\*\*" SKILL.md || true)"
    if [[ "$count" -ge 2 ]]; then
        pass "\"$name\" in both plan review and quick reference"
    elif [[ "$count" -ge 1 ]]; then
        fail "\"$name\" found $count time(s) (expected in both Phase 2.5 and Phase 6)"
    else
        fail "\"$name\" not found in SKILL.md"
    fi
done

# ─────────────────────────────────────────────
section "8. PROJECT.md template has required sections"
# ─────────────────────────────────────────────

required_sections=(
    "Build & Test Commands"
    "Architecture Patterns"
    "Standards to Verify"
    "Blindspots to Check"
    "Commit Conventions"
    "Documentation Location"
)

for section_name in "${required_sections[@]}"; do
    if grep -q "$section_name" PROJECT.md; then
        pass "PROJECT.md has \"$section_name\""
    else
        fail "PROJECT.md missing \"$section_name\""
    fi
done

# ─────────────────────────────────────────────
section "9. No project-specific leaks in core files"
# ─────────────────────────────────────────────

core_files=(
    "SKILL.md"
    "references/chunk-template.md"
    "references/tracker-schema.md"
    "references/quality-checklist.md"
)
leaked_terms=("gradlew" "Hilt" "Room" "Jetpack" "Material 3" "AndroidManifest")

leak_found=false
for file in "${core_files[@]}"; do
    for term in "${leaked_terms[@]}"; do
        if grep -qi "$term" "$file" 2>/dev/null; then
            fail "$file contains project-specific term \"$term\""
            leak_found=true
        fi
    done
done
if ! $leak_found; then
    pass "No project-specific terms in core files"
fi

# ─────────────────────────────────────────────
section "10. Example project configs are valid"
# ─────────────────────────────────────────────

for config in project-configs/*.md; do
    basename="$(basename "$config")"
    for section_name in "${required_sections[@]}"; do
        if grep -q "$section_name" "$config"; then
            pass "$basename has \"$section_name\""
        else
            fail "$basename missing \"$section_name\""
        fi
    done
done

# ─────────────────────────────────────────────
section "11. SKILL.md frontmatter follows skills spec"
# ─────────────────────────────────────────────

# Check required/recommended frontmatter fields
if grep -qP '^name:' SKILL.md; then
    skill_name="$(grep -oP '^name:\s*\K\S+' SKILL.md)"
    pass "Has 'name' field: $skill_name"
    # Validate name format: lowercase, numbers, hyphens only
    if echo "$skill_name" | grep -qP '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
        pass "Name format is valid (lowercase, hyphens)"
    else
        fail "Name '$skill_name' should be lowercase letters, numbers, and hyphens only"
    fi
else
    fail "SKILL.md missing 'name' field"
fi

if grep -qP '^description:' SKILL.md; then
    pass "Has 'description' field"
else
    fail "SKILL.md missing 'description' field"
fi

# Check for $ARGUMENTS usage (skill receives user input)
if grep -q '\$ARGUMENTS' SKILL.md; then
    pass "SKILL.md uses \$ARGUMENTS placeholder"
else
    fail "SKILL.md missing \$ARGUMENTS (user input won't reach the process)"
fi

# Check for non-standard frontmatter fields
# Extract frontmatter (between first and second ---)
frontmatter="$(sed -n '2,/^---$/p' SKILL.md | head -n -1)"
known_fields="name|description|argument-hint|disable-model-invocation|user-invocable|allowed-tools|model|effort|context|agent|hooks"
unknown_fields="$(echo "$frontmatter" | grep -oP '^\K[a-z][a-z_-]*(?=:)' | grep -vP "^($known_fields)$" || true)"
if [[ -z "$unknown_fields" ]]; then
    pass "No non-standard frontmatter fields"
else
    while IFS= read -r field; do
        [[ -z "$field" ]] && continue
        fail "Non-standard frontmatter field: '$field'"
    done <<< "$unknown_fields"
fi

# ─────────────────────────────────────────────
section "12. SKILL.md is under 500 lines"
# ─────────────────────────────────────────────

skill_lines="$(wc -l < SKILL.md)"
if [[ "$skill_lines" -le 500 ]]; then
    pass "SKILL.md is $skill_lines lines (limit: 500)"
else
    fail "SKILL.md is $skill_lines lines (recommended limit: 500)"
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
printf "\n\033[1m━━━ Results ━━━\033[0m\n"
printf "  \033[32m%d passed\033[0m\n" "$PASS"

if [[ "$FAIL" -gt 0 ]]; then
    printf "  \033[31m%d failed\033[0m\n" "$FAIL"
    printf "\n\033[31mFailures:\033[0m\n"
    for err in "${ERRORS[@]}"; do
        printf "  - %s\n" "$err"
    done
    exit 1
else
    printf "  \033[32m0 failed\033[0m\n"
    printf "\n\033[32mAll checks passed.\033[0m\n"
    exit 0
fi
