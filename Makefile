.PHONY: test sync

sync:
	pwsh -NoProfile -File scripts/sync-agents.ps1
	pwsh -NoProfile -File scripts/sync-ai.ps1 -SkipAuth -SkipMcp

test:
	pwsh -NoProfile -Command "Invoke-Pester -Path './tests' -Output Detailed"
