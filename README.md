<p align="center">
  <img src="https://s3.eu-west-2.amazonaws.com/dependabot-images/logo-with-name-horizontal.svg?v5" alt="Dependabot" width="336">
</p>

# Dependabot

Welcome to the public home of Dependabot. This repository serves 2 purposes:

1. It houses the source code for Dependabot Core, which is the heart of [Dependabot][dependabot]. Dependabot Core handles the logic for updating dependencies on GitHub (including GitHub Enterprise), GitLab, and Azure DevOps. If you want to host your own automated dependency update bot then this repo should give you the tools you need. A reference implementation is available [here][dependabot-script].
2. It is the public issue tracker for issues related to Dependabot's updating logic. For issues about Dependabot the service, please contact [GitHub support][support]. While the distinction between Dependabot Core and the service can be fuzzy, a good rule of thumb is if your issue is with the _diff_ that Dependabot created, it belongs here and for most other things the GitHub support team is best equipped to help you.

## Got feedback?

https://github.com/github/feedback/discussions/categories/dependabot-feedback

## Contributing to Dependabot

Currently, the Dependabot team is not accepting support for new ecosystems. We are prioritising upgrades to already supported ecosystems at this time.

Please refer to the [CONTRIBUTING][contributing] guidelines for more information.

### Disclosing security issues

If you believe you have found a security vulnerability in Dependabot please submit the vulnerability to GitHub Security [Bug Bounty](https://bounty.github.com/) so that we can resolve the issue before it is disclosed publicly.

## What's in this repo?

Dependabot Core is a collection of packages for automating dependency updating
in Ruby, JavaScript, Python, PHP, Elixir, Elm, Go, Rust, Java and
.NET. It can also update git submodules, Docker files, and Terraform files.
Highlights include:

- Logic to check for the latest version of a dependency *that's resolvable given
  a project's other dependencies*
- Logic to generate updated manifest and lockfiles for a new dependency version
- Logic to find changelogs, release notes, and commits for a dependency update

### Other Dependabot resources

In addition to this library, you may be interested in the [dependabot-script][dependabot-script] repo,
which provides a collection of scripts that use this library to update dependencies on GitHub Enterprise, GitLab
or Azure DevOps

## Running with Docker

Some ecosystems in Dependabot Core have specific system dependencies.
For example, running the `composer` ecosystem requires
a particular version of `php` and other libraries to be installed.
As such, we use containers to build and run Dependabot Core.

The official Docker images are hosted
on Docker Hub at [`dependabot/dependabot-core`](https://hub.docker.com/r/dependabot/dependabot-core)
and on GitHub Container Registry at [`ghcr.io/dependabot/dependabot-core`](https://github.com/dependabot/dependabot-core/pkgs/container/dependabot-core).

You can simulate a dependency update job with the `dry-run` script.
It takes two positional arguments,
the package manager and a whole GitHub repo name (i.e. `user/repo`),
and prints the diff that would be generated to standard output.

```bash
$ docker run -it dependabot/dependabot-core \
    bin/dry-run.rb go_modules rsc/quote
=> fetching dependency files
=> parsing dependency files
=> updating 2 dependencies
...
```

> **Note**:
> If the dependency files are not in the top-level directory,
> then you must also specify its path with `--dir /path/to/project`.

## Developing

### Cloning the repository

Clone the repository with the following command:

```console
$ git clone https://github.com/dependabot/dependabot-core.git
```

On Windows,
this may fail with a "Filename too long" error.
You can fix this by running the following commands:

```console
> cd dependabot-core
> git config core.longpaths true
> git reset --hard
```

For more information,
see the [Git for Windows wiki](https://github.com/git-for-windows/git/wiki/Git-cannot-create-a-file-or-directory-with-a-long-path).

### Installing Earthly

Dependabot Core uses [Earthly](https://earthly.dev/) for build automation.
You can install Earthly by running the following commands:

```console
# macOS (requires Docker for Mac and Git)
$ brew install earthly/earthly/earthly && earthly bootstrap

# Linux / Windows (WSL 2) (requires Docker and Git)
$ sudo /bin/sh -c \
    'wget https://github.com/earthly/earthly/releases/latest/download/earthly-linux-amd64 \
      -O /usr/local/bin/earthly && \
     chmod +x /usr/local/bin/earthly && \
     /usr/local/bin/earthly bootstrap --with-autocomplete'
```

### Testing and linting

Each ecosystem has its own `Earthfile`
with instructions for installing system dependencies,
building native helpers (if needed),
and running tests.

To test the behavior of a particular ecosystem,
you can run its `test` target

```console
$ earthly ./go_modules+test
```

To check for code style and other violations,
you can run an ecosystem's `lint` target.

```console
$ earthly ./go_modules+lint
```

> **Note**:
> Any changes to system dependencies or native helpers
> are automatically reflected the next time an `earthly` command is run.

### Building the container image

Run the `earthly` command with the `docker` target in the top-level directory
to build and save the image `dependabot/dependabot-core` locally
with the `latest` tag.

```console
$ earthly +docker

$ docker run -it dependabot/dependabot-core
```

For local development,
pass the `--development=true` argument to build an image
with debugging utilities and other helpful tools.

```console
$ earthly +docker --development=true

$ docker run -it dependabot/dependabot-core-development bin/sh
```

### Debugging native helpers

Some Dependabot packages use _native helpers_,
or small executables written in the ecosystem's native language.
Native helpers are run in separate processes
and communicate with the host process using JSON.

To print log statements from native helpers,
set the `DEBUG_HELPERS` environment variable.

```console
$ docker run -it dependabot/dependabot-core-development \
    DEBUG_HELPERS=true bin/dry-run.rb bundler dependabot/demo --dir="/ruby"
```

To pause execution and debug a single native helper function,
set the `DEBUG_FUNCTION` environment variable to the name of that function.

```console
$ docker run -it dependabot/dependabot-core-development \
    DEBUG_FUNCTION=parsed_gemfile bin/dry-run.rb bundler dependabot/demo --dir="/ruby"
```

### Debugging with Visual Studio Code and Docker

Visual Studio Code has built-in support for
[debugging Docker containers][vsc-remote-containers].
Install the  [Remote - Containers extension][vsc-remote-containers-ext],
open the Command Palette (<kbd>⇧</kbd><kbd>⌘</kbd><kbd>P</kbd>),
and select "Remote-Containers: Reopen in Container".

Run the "Debug Dry Run" configuration (<kbd>F5</kbd>),
and you'll be prompted for an ecosystem and repository to perform a dry run.

You can also debug individual tests;
run the "Debug Tests" configuration (<kbd>F5</kbd>)
and you'll be prompted for an ecosystem and rspec path.

> **Note**:
> The `Clone Repository ...` commands of the Remote Containers extension
> aren't currently supported.
> Instead, clone the repository manually
> and use the `Reopen in Container` or `Open Folder in Container...` commands.

### Profiling

You can profile a dry-run by passing the `--profile` flag,
or by tagging an rspec test with `:profile` and running `rspec`.
The resulting profile information will be written to
a `stackprof-<id>.dump` file in the `tmp/` directory,
You can generate a flamegraph from this file by running the following command:

```console
$ stackprof --d3-flamegraph tmp/stackprof-<id>.dump > tmp/flamegraph.html
```

## Releasing

Triggering the jobs that will push the new gems is done by following the steps below.

- Ensure you have the latest merged changes:  `git checkout main` and `git pull`
- Generate an updated `CHANGELOG`, `version.rb`, and the rest of the needed commands:  `bin/bump-version.rb patch`
- Edit the `CHANGELOG` file and remove any entries that aren't needed
- Run the commands that were output by running `bin/bump-version.rb patch`

## Architecture

Dependabot Core is a collection of Ruby packages (gems), which contain the
logic for updating dependencies in several languages.

### `dependabot-common`

The `common` package contains all general-purpose/shared functionality. For
instance, the code for creating pull requests via GitHub's API lives here, as
does most of the logic for handling Git dependencies (as most languages support
Git dependencies in one way or another). There are also base classes defined for
each of the major concerns required to implement support for a language or
package manager.

### `dependabot-{package-manager}`

There is a gem for each package manager or language that Dependabot
supports. At a minimum, each of these gems will implement the following
classes:

| Service          | Description                                                                                   |
|------------------|-----------------------------------------------------------------------------------------------|
| `FileFetcher`    | Fetches the relevant dependency files for a project (e.g., the `Gemfile` and `Gemfile.lock`). See the [README](https://github.com/dependabot/dependabot-core/blob/main/common/lib/dependabot/file_fetchers/README.md) for more details. |
| `FileParser`     | Parses a dependency file and extracts a list of dependencies for a project. See the [README](https://github.com/dependabot/dependabot-core/blob/main/common/lib/dependabot/file_parsers/README.md) for more details. |
| `UpdateChecker`  | Checks whether a given dependency is up-to-date. See the [README](https://github.com/dependabot/dependabot-core/tree/main/common/lib/dependabot/update_checkers/README.md) for more details. |
| `FileUpdater`    | Updates a dependency file to use the latest version of a given dependency. See the [README](https://github.com/dependabot/dependabot-core/tree/main/common/lib/dependabot/file_updaters/README.md) for more details. |
| `MetadataFinder` | Looks up metadata about a dependency, such as its GitHub URL. See the [README](https://github.com/dependabot/dependabot-core/tree/main/common/lib/dependabot/metadata_finders/README.md) for more details. |
| `Version`        | Describes the logic for comparing dependency versions. See the [hex Version class](https://github.com/dependabot/dependabot-core/blob/main/hex/lib/dependabot/hex/version.rb) for an example. |
| `Requirement`    | Describes the format of a dependency requirement (e.g. `>= 1.2.3`). See the [hex Requirement class](https://github.com/dependabot/dependabot-core/blob/main/hex/lib/dependabot/hex/requirement.rb) for an example. |

The high-level flow looks like this:

<p align="center">
  <img src="https://s3.eu-west-2.amazonaws.com/dependabot-images/package-manager-architecture.svg" alt="Dependabot architecture">
</p>

### `dependabot-omnibus`

This is a "meta" gem, that simply depends on all the others. If you want to
automatically include support for all languages, you can just include this gem
and you'll get all you need.

## Why is this public?

As the name suggests, Dependabot Core is the core of Dependabot (the rest of the
app is pretty much just a UI and database). If we were paranoid about someone
stealing our business then we'd be keeping it under lock and key.

Dependabot Core is public because we're more interested in it having an
impact than we are in making a buck from it. We'd love you to use
[Dependabot][dependabot] so that we can continue to develop it, but if you want
to build and host your own version then this library should make doing so a
*lot* easier.

If you use Dependabot Core then we'd love to hear what you build!

## License

We use the License Zero Prosperity Public License, which essentially enshrines
the following:
- If you would like to use Dependabot Core in a non-commercial capacity, such as
  to host a bot at your workplace, then we give you full permission to do so. In
  fact, we'd love you to and will help and support you however we can.
- If you would like to add Dependabot's functionality to your for-profit
  company's offering then we DO NOT give you permission to use Dependabot Core
  to do so. Please contact us directly to discuss a partnership or licensing
  arrangement.

If you make a significant contribution to Dependabot Core then you will be asked
to transfer the IP of that contribution to Dependabot Ltd so that it can be
licensed in the same way as the above.

## History

Dependabot and Dependabot Core started life as [Bump][bump] and
[Bump Core][bump-core], back when Harry and Grey were working at
[GoCardless][gocardless]. We remain grateful for the help and support of
GoCardless in helping make Dependabot possible - if you need to collect
recurring payments from Europe, check them out.


[dependabot]: https://dependabot.com
[dependabot-status]: https://api.dependabot.com/badges/status?host=github&identifier=93163073
[dependabot-script]: https://github.com/dependabot/dependabot-script
[contributing]: https://github.com/dependabot/dependabot-core/blob/main/CONTRIBUTING.md
[bump]: https://github.com/gocardless/bump
[bump-core]: https://github.com/gocardless/bump-core
[gocardless]: https://gocardless.com
[ghcr-core-dev]: https://github.com/dependabot/dependabot-core/pkgs/container/dependabot-core-development
[support]: https://support.github.com/
[vsc-remote-containers]: https://code.visualstudio.com/docs/remote/containers
[vsc-remote-containers-ext]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
