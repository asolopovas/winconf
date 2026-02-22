.PHONY: test

test:
	pwsh -NoProfile -Command "Invoke-Pester -Path './tests' -Output Detailed"
