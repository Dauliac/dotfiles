---
name: slack-upload-file
description: Upload a file to a Slack channel or DM using the CURRENT 3-step external-URL flow — `files.getUploadURLExternal` → HTTP PUT the bytes → `files.completeUploadExternal`. The old `files.upload` is deprecated. Covers channel sharing, initial comment, thread-attached uploads, and grabbing the permalink. Trigger on: "upload file to #channel", "share a screenshot in slack", "attach this log to slack", "post an image to slack", "send a pdf to @user on slack". For posting a bare permalink (already-uploaded file), that's just [[slack-send-message]] with a link.
---

# slack-upload-file — file upload (3-step external flow)

Slack retired `files.upload` in favor of an external-URL flow. Three
calls, always in this order.

## Step 1 — Reserve an upload URL

```bash
resp=$(slack api files.getUploadURLExternal \
  filename=deploy.log \
  length=$(stat -c%s deploy.log))

upload_url=$(echo "$resp" | jq -r '.upload_url')
file_id=$(echo "$resp"    | jq -r '.file_id')
```

Optional: `alt_txt=…` (accessibility text), `snippet_type=…` (for
syntax-highlighted text snippets: `text`, `python`, `json`, `bash`, …).

## Step 2 — PUT the bytes

Not a Slack API call — a raw HTTP PUT to the URL Slack handed back.
`slack api` cannot do this; use `curl`:

```bash
curl -sf -X POST \
  -F filename=@deploy.log \
  "$upload_url"
```

Or, for a real streaming PUT of stdin:

```bash
some-command | curl -sf -X POST -F 'file=@-;filename=deploy.log' "$upload_url"
```

## Step 3 — Finalize + share

```bash
slack api files.completeUploadExternal --json "$(jq -n \
  --arg fid "$file_id" \
  --arg fname deploy.log \
  --arg chan  C0123ABC \
  '{files: [{id: $fid, title: $fname}], channel_id: $chan, initial_comment: "latest deploy log"}')"
```

Fields:

- `files: [{id, title}]` — repeat to batch multiple files into one share.
- `channel_id` — target channel / DM / MPIM. Omit to store without sharing.
- `initial_comment` — text posted alongside the file.
- `thread_ts` — attach the upload as a thread reply.

## Grab the permalink

The `completeUploadExternal` response contains `files: [{permalink,
permalink_public, url_private, id, …}]`. Save `permalink` — that's
what you'd embed in a follow-up message.

## Idempotent one-shot function

```bash
slack_upload() {
  local file=$1 channel=$2 comment=${3:-}
  local size url fid
  size=$(stat -c%s "$file")
  read -r url fid < <(slack api files.getUploadURLExternal \
    filename="$(basename "$file")" length="$size" \
    | jq -r '[.upload_url, .file_id] | @tsv')
  curl -sf -X POST -F "file=@$file" "$url" >/dev/null
  slack api files.completeUploadExternal --json "$(jq -n \
    --arg fid "$fid" --arg t "$(basename "$file")" \
    --arg c "$channel" --arg m "$comment" \
    '{files: [{id:$fid, title:$t}], channel_id:$c, initial_comment:$m}')"
}
```

## Common errors

| Error | Fix |
| --- | --- |
| `missing_scope` | `files:write` for upload; `files:read` to fetch permalink data back. |
| `channel_not_found` / `not_in_channel` | Same as [[slack-send-message]] — token's user must be in the channel. |
| `file_upload_failed` (step 2) | Wrong `length` in step 1, or the URL expired (they're short-lived — don't sit on them). |
| Old code referencing `files.upload` | Migrate to this 3-step flow. `files.upload` still exists but is deprecated and rate-limited hard. |
