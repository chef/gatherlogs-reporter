# Gatherlog reports with Inspec

[![Build Status](https://travis-ci.com/teknofire/gatherlogs-inspec-profiles.svg?branch=master)](https://travis-ci.com/teknofire/gatherlogs-inspec-profiles)

This is a set of tools to generate reports from gather-log bundles for various Chef products.

* Chef: https://chef.io
* Get Chef-InSpec from: https://inspec.io

## Requirements

1. Chef InSpec (currently tested with v4 but should work with v3)
2. ruby 2.5+
3. bundler >= 2.0

## Installation

### Habitat package

**NOTE**: This brings in Chef InSpec v4 which requires [license acceptance](https://docs.chef.io/chef_license_accept.html) in order to run.

```bash
hab pkg install will/gatherlogs_reporter
hab pkg exec will/gatherlogs_reporter gatherlogs_report --help
```

### Source code

1. Download code and the gems

  ```bash
  git clone https://github.com/teknofire/gatherlogs-reporter
  cd gatherlogs-reporter
  bundle
  ```

2. Add `gatherlogs-reporter/bin` to your path, put this in your `.bashrc` or the equivalent file for your shell.

  ```
  export PATH=$PATH:PATH/TO/gatherlogs-reporter/bin;
  ```

## Usage

You will need to be in the directory with the expanded gather-logs tar file to run this tool and should be in the same directory where you find the `installed-packages.txt` or `platform_version.txt` files.

The `check_logs` tool will attempt to detect the product used to generate the gather-logs bundle if one hasn't been specified, if it's unable to for some reason you need to give it the profile name.

Currently available profiles
  * `automate`
  * `automate2`
  * `chef-server`
  * `chef-backend`

To see all the available options use

```
gatherlogs_report --help
```

## Example output

```
Running inspec profile for chef-server...

System report
---------------------------------------------------------------------------------------
         Product: Chef-Server 12.8.0
       CPU Cores: 2
       CPU Model: Intel(R) Xeon(R) CPU E7- 2870  @ 2.40GHz
    Total Memory: 15872 MB
     Free Memory: 8834 MB
        Platform: Red Hat Enterprise Linux Server release 6.5 (Santiago)
          Uptime: 02:47:49 up 6 days, 18:33,  0 users,  load average: 0.35, 0.14, 0.09
    DRBD Enabled: Yes
        Topology: "ha"
       Reporting: 1.3.0
          Manage: Not Installed
Push-Jobs Server: 2.0.0~alpha.3
---------------------------------------------------------------------------------------

Inspec report
--------------------------------------------------------------------------------
✗ 000.gatherlogs.chef-server.package: check that chef-server is installed
  ⓘ The installed version of Chef-Server is old and should be upgraded
    Installed version: 12.8.0

✗ 010.gatherlogs.chef-server.required_cpu_cores: Check that the system has the required number of cpu cores
  ⓘ Chef recommends that the Chef-Server and Frontend systems have at least 4 cpu cores.
    Please make sure the system means the minimum hardware requirements

  ✩ https://docs.chef.io/chef_system_requirements.html#chef-server-on-premises-or-in-cloud-environment

  ✗ cpu_info total should cmp >= 4

    expected it to be >= 4
         got: 2

    (compared using `cmp` matcher)

✗ 010.gatherlogs.chef-server.required_memory: Check that the system has the required amount of memory
  ⓘ Chef recommends that the Chef-Server system has at least 8GB of memory.
    Please make sure the system means the minimum hardware requirements

  ✩ https://docs.chef.io/chef_system_requirements.html#chef-server-on-premises-or-in-cloud-environment

  ✗ memory total_mem should cmp >= 7168
  ✗ memory free_swap should cmp > 0

    expected it to be > 0
         got: nil

    (compared using `cmp` matcher)

✗ 030.gatherlogs.chef-server.check_for_drbd: Check to see if the system is using legacy DRDB HA configuration
  ⓘ Chef-server is using a legacy DRBD HA configuration.
    This feature will reach end-of-life for support on March 31, 2019.

  ✩ https://blog.chef.io/2018/10/02/end-of-life-announcement-for-drbd-based-ha-support-in-chef-server/
```

## Autocompletions

If you use the zsh shell you can add autocompletions for the `gatherlogs_report` command by adding the following
to your `~/.zshrc` config

```
source "/PATH/TO/gatherlogs/completions/gatherlogs_report.zsh"
```
