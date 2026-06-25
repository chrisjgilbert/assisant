<!--
  TEMPLATE for ONE append-only entry in ~/brain/signals/new-channels.md.

  signals/new-channels.md is APPEND-ONLY. On each pull, the pull skill diffs the
  channels you're a MEMBER of against include ∪ ignore in config/sources.yml and
  appends a block like this for each newly-discovered membership. Copy this block
  to the BOTTOM of the file; never rewrite or delete earlier entries.

  This is a PROPOSAL ONLY. Discovery NEVER auto-subscribes. The human reviews
  each entry and promotes the channel to `include` or `ignore` in sources.yml by
  hand, then sets status below. Replace every <FILL IN ...> marker.
-->

## [<FILL IN YYYY-MM-DD discovered>] new-channel | <FILL IN #channel-name>

- **channel name:** <FILL IN #channel-name>
- **channel_id:** <FILL IN stable Slack ID, e.g. C0123ABCD>   <!-- internally we key on the ID; you edit by name -->
- **topic / purpose:** <FILL IN channel topic or what it's for>
- **joined:** <FILL IN YYYY-MM-DD you were added / created it>
- **recent activity:** <FILL IN level, e.g. high (~40 msgs/wk) | low (quiet) | none>
- **suggested disposition:** <FILL IN include | ignore>
- **status:** unreviewed   <!-- unreviewed | promoted-to-include | promoted-to-ignore (human sets this) -->

> Proposal only. Discovery never auto-subscribes. Promote it yourself in config/sources.yml.
