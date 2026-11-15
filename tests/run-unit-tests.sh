#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
test_count=0

if ! command -v "$godot_bin" >/dev/null 2>&1; then
	printf 'Godot executable not found: %s\n' "$godot_bin" >&2
	exit 127
fi

while IFS= read -r test_file; do
	test_count=$((test_count + 1))
	printf '\n==> %s\n' "${test_file#"$repo_root"/}"
	"$godot_bin" --headless --path "$repo_root" --script "${test_file#"$repo_root"/}"
done < <(find "$repo_root/tests/unit" -type f -name '*_test.gd' | sort)

if [ "$test_count" -eq 0 ]; then
	printf 'No Godot unit test scripts found.\n' >&2
	exit 1
fi
