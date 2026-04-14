# Unable to complete fix automatically

## What the reviewer wants

Add `--remote` to the `copilot` CLI invocations inside the GitHub Actions coding-agent workflow (`.github/workflows/coding-agent.yml`), so that each automated coding-agent run streams a live session link that maintainers can monitor from web or mobile.

Specifically, the two `copilot` calls in **Step 6** of `coding-agent.yml` need `--remote` added:

```yaml
# Run Copilot CLI (new session)
copilot --allow-all --remote --prompt "$PROMPT" 2>copilot-stderr.log | tee copilot-output.txt

# Run Copilot CLI (resume session)
copilot --allow-all --remote $RESUME_ARGS \
  --prompt "Review feedback has been posted..." \
  2>copilot-stderr.log | tee copilot-output.txt
```

The remote session URL and QR code printed by the CLI will appear in the Actions run log, satisfying the issue's "observe the logs" requirement.

## Why the agent cannot make this change

The coding-agent rules explicitly prohibit modifying any file under `.github/workflows/`. These files are CI/CD infrastructure managed by the maintainer.

## What the maintainer should do

Manually add `--remote` to the two `copilot` invocations in `.github/workflows/coding-agent.yml` (lines ~238 and ~252 in Step 6).

Note: Remote CLI sessions require the Copilot Business/Enterprise admin to [enable remote control and CLI policies](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-remote-access#administering-remote-access) before this will work.
