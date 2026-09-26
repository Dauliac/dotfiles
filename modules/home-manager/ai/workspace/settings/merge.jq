# Deep-merge Claude Code settings fragments onto a base settings file.
#
# Invocation: jq -s -f merge.jq --arg retired "<regex>" base.json frag1.json ...
#
# --arg retired: jq regex (alternation-friendly, e.g. "foo|bar"). Hook
# entries in the base whose .hooks[0].command matches are dropped before
# the merge. Reverses the forward-only limitation for commands whose
# defining nix module has been removed. Empty string = no pruning.
#
# Merge rules:
#   - Objects: recursive merge, later value wins on scalar conflict (so
#     fragments layered atop base win on the keys they declare, but keys
#     they don't mention survive untouched — that's how runtime writes by
#     Claude Code / codegraph / mm-* tools survive rebuild).
#   - Arrays of strings (e.g. permissions.allow, permissions.deny): union.
#   - Arrays of hook objects (elements have `matcher` + `hooks[0].command`):
#     union, deduped by (matcher, first command).
#   - Other object arrays: union, deduped by full-value equality.
#   - Scalars: later wins.

def merge_arrays(a; b):
  if (a + b) == [] then []
  elif all((a + b)[]; type == "string") then
    (a + b) | unique
  elif all((a + b)[]; type == "object") then
    if all((a + b)[]; has("matcher")) then
      (a + b) | unique_by([.matcher, (.hooks[0].command // "")])
    else
      (a + b) | unique
    end
  else
    (a + b) | unique
  end;

def deep_merge(a; b):
  if (a | type) == "object" and (b | type) == "object" then
    reduce (b | keys_unsorted[]) as $k (a;
      if .[$k] == null then .[$k] = b[$k]
      else .[$k] = deep_merge(.[$k]; b[$k])
      end
    )
  elif (a | type) == "array" and (b | type) == "array" then
    merge_arrays(a; b)
  else
    b
  end;

def prune_retired(pat):
  if pat == "" then .
  elif type == "object" and (.hooks | type) == "object" then
    .hooks |= with_entries(
      .value |= map(select((.hooks[0].command // "") | test(pat) | not))
    )
  else . end;

# Fold: start from base (pruned), reduce fragments (.[1:]) onto it.
reduce .[1:][] as $frag ((.[0] | prune_retired($retired)); deep_merge(.; $frag))
