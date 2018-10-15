# Gatherlogs InSpec Profile

This is a proof of concept to see if using InSpec to do some initial
validation on gatherlog output from chef-products is viable.

Get InSpec from: http://inspec.io

## Requirements

1. inspec (currently tested with v2 but should work with v1)
2. ruby 2.4+
3. bundler

## Installation

1. Download code and the gems

  ```bash
  git clone https://github.com/teknofire/gatherlogs-inspec-profiles
  cd gatherlogs-inspec-profiles
  bundle
  ```

2. Add `gatherlogs-inspec-profiles/bin` to your path, put this in your `.bashrc` or the equivalent file for your shell.

  ```
  export PATH=$PATH:PATH/TO/gatherlogs-inspec-profiles/bin;
  ```

## Usage

You will need to be in the directory with the expanded gather-logs tar file to run this tool and should be in the same directory where you find the `installed-packages.txt` or `platform_version.txt` files.

The `check_logs` tool will attempt to detect the product used to generate the gather-logs bundle if one hasn't been specified, if it's unable to for some reason you need to give it the profile name.

Currently available profiles
  * `chef-server`
  * `automate`
  * `automate2`
  * `chef-backend`

Available options

```
Usage:
    check_logs [OPTIONS] [PROFILE]

Parameters:
    [PROFILE]                     profile to execute

Options:
    -p, --path PATH               Path to the gatherlogs for inspection (default: ".")
    -d, --debug                   Enable debug output
    --profiles                    Show available profiles
    -v, --verbose                 Show inspec test output
    -a, --all                     Show all tests, default is to only show failed tests
    --version                     Show current version
    -h, --help                    print help
```

## Example output

```
$ check_log

InSpec profile for Chef-Server generated gather-logs
  × gatherlogs.chef-server.package: check that chef-server is installed
    ⓘ The installed version of Chef-Server is old and should be upgraded

  × gatherlogs.chef-server.postgreql-upgrade-applied: make sure customer is using chef-server version that includes postgresl 9.6
    ⓘ Chef Server < 12.16.2 uses PostgreSQL 9.2 and will perform a major upgrade
      to 9.6.  Please make sure there is enough disk space available to perform
      the upgrade as it will duplicate the database on disk.

  × chef-server.gatherlogs.reporting-with-2018-partition-tables: make sure installed reporting version has 2018 parititon tables fix
    ⓘ Reporting < 1.7.10 has a bug where it does not create the 2018
      partition tables. In order to fix this the user should install >= 1.8.0
      and follow the instructions in this KB:
      https://getchef.zendesk.com/hc/en-us/articles/360001425252-Fixing-missing-2018-Reporting-partition-tables
```

## Autocompletions

If you use the zsh shell you can add autocompletions for the `check_log` command by adding the following
to your `~/.zshrc` config

```
source "/PATH/TO/gatherlogs/completions/check_logs.zsh"
```

## TODO

* [ ] It would be nice if we could test to see if `noexec` is set on `/tmp`
