---
name: s3-watch
description: When work touches S3 (aws s3 cp/sync, terraform on an S3 bucket, an artifact upload, a data pipeline write), open `stu` in a herdr split scoped to the specific bucket + prefix + AWS profile in play. Auto-closes on idle. Reach for it after any mutating S3 command or when the user asks "did that upload land?".
---

# s3-watch — scoped stu TUI for the bucket + prefix you just wrote to

`stu` is an S3 terminal UI. The default launches a full account listing —
useless when the user only cares about one bucket. Always scope.

## Gathering context

You need:

1. **AWS profile**: from `AWS_PROFILE`, the `--profile` flag on the command
   you just ran, or the current terraform workspace's provider config.
2. **Bucket**: from the s3:// URL, the terraform resource, or the manifest.
3. **Prefix** (optional but strongly preferred): the key prefix under
   which the work happened. Without a prefix, stu loads the whole bucket
   listing — potentially thousands of keys.
4. **Region** (optional): if the bucket is outside the profile's default.

## Single-TUI invocation

```bash
PROFILE="${AWS_PROFILE:-default}"
BUCKET=my-app-artifacts
PREFIX=releases/2026-08-02/

herdr-tui launch \
  --label "s3:$BUCKET/$PREFIX" \
  --auto-close-on-idle 90 \
  -- stu --profile "$PROFILE" --bucket "$BUCKET" --prefix "$PREFIX"
```

## When the operation has a clear terminal state

For a sync/upload where you know the final key(s), close automatically as
soon as they land:

```bash
herdr-tui launch \
  --label "s3-upload:$BUCKET" \
  --auto-close-when "aws --profile $PROFILE s3api head-object --bucket $BUCKET --key $KEY >/dev/null 2>&1" \
  --auto-close-timeout 900 \
  -- stu --profile "$PROFILE" --bucket "$BUCKET" --prefix "$PREFIX"
```

## Multiple buckets

If several buckets matter at once, that's the grid case — open a grid tab
and add one `stu` pane per bucket. See [tui-context](#) for the
`grid-open` / `grid-add` flow.

## Failure mode

If `aws sts get-caller-identity --profile "$PROFILE"` fails, the profile
isn't usable — don't spawn the TUI. Report the credentials error in chat
instead.
