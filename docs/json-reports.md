# JSON reports specification

Crater reports are also available in JSON formats, to be consumed by external
tools. This document contains the format used in those reports.

While existing fields won't be removed or changed, new fields or variants can
be added in the future. Expect new content when consuming the reports.

## Results summary

The summary of all the results lives in the `data/results.json` file.

```json
{
    "name": "experiment-name",
    "platforms": {
        "public/linux": {
            "type": "public",
            "os": "linux",
            "mode": "build-and-test",
            "toolchain-1": "stable",
            "toolchain-2": "beta"
        }
    },
    "results": {
        "reg/lazy_static/1.0": {
            "name": {
                "type": "registry",
                "name": "lazy_static",
                "version": "1.0"
            },
            "result": "same-build-pass",
            "platforms": {
                "public/linux": ["build-fail", "build-fail"]
            }
        }
    }
}
```

### Top-level keys

* `name`: the name of the experiment; this name is unique
* `platforms`: a dictionary of the available platforms; the key is the platform
  ID, and its format is unspecified (**do not parse it**), and the value is
  the configuration of that platform
* `results`: a dictionary of the available results; the key is the result ID,
  and its format is unspecified (**do not parse it**), and the value is the
  result itself

### Platform keys

Each platform has these keys:

* `type`: the type of platform; currently it can only be `public`, but new
  types might be added in the future
* `toolchain-1`: the name of the first toolchain to compare
* `toolchain-2`: the name of the second toolchain to compare

The `public` platform also contains the following keys:

* `os`: the name of the OS the platform is using; currently it can only be
  `linux`, but new OSes might be added in the future
* `mode`: the experiment mode the platform is running; it can currently be
  `check-only`, `build-only`, `build-and-test`

### Result keys

* `name`: the typed name of the crate
* `result`: the summary of the results across all platforms
* `platforms`: the results of each toolchain in each platform; the key is the
  platform ID, and the value is the list of the two results of the two
  toolchains; note that not all of the platforms might be present

### Crate names

Each crate name has these keys:

* `type`: the type of the crate; currently it can be `registry` or `github`

The `registry` platform also contains the following keys:

* `name`: the name of the crate
* `version`: the tested version (can be null or missing)

The `github` platform also contains the following keys:

* `org`: the name of the owner of the repository
* `name`: the name of the repository
* `sha`: the tested commit (can be null or missing)

### Available summary results

Note that new results might be added in the future.

* `same-test-pass`
* `same-test-skipped`
* `same-test-fail`
* `same-build-fail`
* `regressed`
* `fixed`
* `skipped`
* `unknown`
* `error`

### Available single results

Note that new results might be added in the future.

* `test-pass`
* `test-skipped`
* `test-fail`
* `build-fail`
* `skipped`
* `unknown`
* `error`

## Logs

Logs are available for each crate and platform. Logs are located in the
`{platform-id}/{toolchain}/{crate-id}/log.txt` path, and are not guaranteed to
contain valid UTF-8.

## Detailed results

Detailed results are available for each crate and platform. Detailed results
are located in the `{platform-id}/{toolchain}/{crate-id}/result.json` path.

```json
{
    "result": "build-fail"
}
```

* `result`: the result of this crate on this platform
