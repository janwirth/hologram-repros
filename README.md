# Hologram repro: live reload crashes when a static file vanishes mid-scan

Minimal reproduction of [bartblast/hologram#1379](https://github.com/bartblast/hologram/issues/1379)
(part 1), forked from [hologram_skeleton](https://github.com/bartblast/hologram_skeleton).
Hologram 0.12.2, Elixir 1.20.4, OTP 28.1.1, dev mode in Docker.
Live at https://hologram-live-reload-race-repro.jan-wirth.dev.

## The bug

After a compile, a live reload pass rescans the static dir to reload the asset
path registry:

```
Hologram.LiveReload.reload_runtime/0
  -> Hologram.Assets.PathRegistry.reload/0      # ETS.reset, then populate
    -> Hologram.Commons.FileUtils.list_files_recursively/1
```

`list_files_recursively/1` lists a dir with `File.ls!/1`, then checks each
entry with `File.regular?/1` and `File.dir?/1`. In a real app, `esbuild --watch`
writes to the same dir and removes its old chunk files while the scan runs. An
entry that is gone by the time it is checked is neither regular nor a dir, and
the function raises `ArgumentError Invalid path`.

To make the race deterministic, the repro puts a dangling symlink in
`priv/static/assets`: `File.ls!/1` lists it, and both checks are false, exactly
like a chunk esbuild deleted between the two calls.

## Run it

```bash
docker compose -p hologram-live-reload-race up -d --build   # serves :4101
bin/repro
```

`bin/repro` calls `GET /repro/trigger` (see `lib/hologram_skeleton_web/repro.ex`),
which adds `priv/static/assets/chunk-VANISHED.js` as a dangling symlink, bumps
`@revision` in `app/home_page.ex` so live reload runs a pass, and removes the
symlink again 20 s later. The script then waits 12 s, prints the log and what
`GET /` answers. `GET /repro/reset` runs a clean pass that brings the page back.

On the live deployment, click **Trigger the race** on the page, then
**Reset**.

## Expected

The scan skips the vanished entry, the pass finishes, and the page renders with
its new bundle (`Revision N+1`).

## Actual

On 0.12.2 the scan runs inside `Hologram.LiveReload`'s `handle_call` for
`:bundles_built`, so the live reload GenServer itself crashes (plus its file
watcher and the pass task):

```
[error] GenServer Hologram.LiveReload terminating
** (ArgumentError) Invalid path: "/app/_build/dev/lib/hologram_skeleton/priv/static/assets/chunk-VANISHED.js"
    (hologram 0.12.2) lib/hologram/commons/file_utils.ex:43: Hologram.Commons.FileUtils.list_files_recursively/1
    (hologram 0.12.2) lib/hologram/commons/file_utils.ex:38: Hologram.Commons.FileUtils.list_files_recursively/1
    (hologram 0.12.2) lib/hologram/commons/file_utils.ex:38: Hologram.Commons.FileUtils.list_files_recursively/1
    (hologram 0.12.2) lib/hologram/assets/path_registry.ex:128: Hologram.Assets.PathRegistry.find_assets/1
    (hologram 0.12.2) lib/hologram/assets/path_registry.ex:176: Hologram.Assets.PathRegistry.populate/1
    (hologram 0.12.2) lib/hologram/live_reload.ex:541: Hologram.LiveReload.reload_runtime/0
    (hologram 0.12.2) lib/hologram/live_reload.ex:103: Hologram.LiveReload.handle_call/3
[error] Task #PID<0.8718.0> started from Hologram.LiveReload terminating
** (stop) exited in: GenServer.call(#PID<0.8331.0>, {:bundles_built, [HologramSkeleton.HomePage]}, :infinity)
```

`PathRegistry.reload/0` had already reset its ETS table, so the registry stays
empty, and every page answers 500 until the next successful pass, even after the
vanished file is long gone:

```
[info] GET /
[info] Sent 500 in 256ms
[error] ** (Hologram.AssetNotFoundError) there is no such asset: "hologram/runtime.js"
```

This is worse than on 0.11.1, where the issue was first seen: there the scan ran
in the pass task, which logged `[error] Hologram: live reload pass failed: ...`,
and only the edited page's new bundle 404'd. On 0.12.2 that log line never
appears, because the process that would log it is the one that crashed.

## No way to wait for a pass

Both `bin/repro` and the trigger page `sleep` and hope the pass is done:
Hologram has no API that says when a live reload pass has finished or whether
it compiled. Part 2 of the issue proposes `Hologram.LiveReload.await_idle/1`
for that.

## Fix

[janwirth/hologram@4ff25d3](https://github.com/janwirth/hologram/commit/4ff25d352e692cd1c89238f8fbab8c7cb42de75a):
`list_files_recursively/1` skips an entry that is gone when it is checked, and
treats a `File.ls` error on a vanished subdirectory as an empty dir. A path
that never existed still raises at the top level.
