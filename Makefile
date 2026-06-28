.PHONY: test sync

sync:
	git submodule update --init --remote agents
	pwsh -NoProfile -File scripts/sync-ai.ps1 -SkipAuth -SkipMcp

test:
	pwsh -NoProfile -Command "Invoke-Pester -Path './tests' -Output Detailed"
