# Gather-log reports with Chef InSpec

This is a set of tools to generate reports from gather-log bundles for various Chef products.

* Chef: https://chef.io
* Get Chef InSpec from: https://inspec.io

## Requirements

1. ruby 2.6+
2. bundler >= 2.0
3. git >= 2.22

## Installation

```bash
hab pkg install chef/gatherlogs_reporter
hab pkg exec chef/gatherlogs_reporter gatherlogs_report --help
```

## Usage

To run this tool you will need access to the `gather-log` output from a supported Chef product.  

1. Generate a log bundle from a Chef product

    **Note:** See *Generating log bundles for Chef products* below for how to generate log bundles for all supported products.

    For example on a Chef Infra Server run:
    ```bash
    chef-server-ctl gather-logs
    ```  

    This will generate a `tar.bz2` or `tar.gz` file that contains the logs and various information about the product installation.

2. Generate a report from the log bundle run:

   ```bash
   gatherlogs_report -p PATH/TO/LOG_BUNDLE.tar.bz2
   ```

##### Alternatively you can run it against the extract the log bundle

1. Extract the logs

    ```bash
    tar xvfz LOG_BUNDLE.tar.bz2
    ```

2. `cd` into the directory with the extracted logs.  

    ```bash
    # default directory structure <SERVER_HOSTNAME>/<BUNDLE_TIMESTAMP>
    cd chef.myhostname.com/2019-06-20-16:54:01
    ```
3. Run the reporter: `gatherlogs_report`

    *No options are required as it will look in the current directory for the extracted files by default.*

The `gatherlogs_report` command will attempt to detect the product used to generate the gather-logs bundle, if for some reason it's unable to do so, ensure that you are in the correct directory with the log bundle or specify the product name manually.

To see all the available options use

```bash
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

Gather-log report
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

## Currently supported product profiles:
  * `automate`
  * `automate2`
  * `chef-server`
  * `chef-backend`

## Generating log bundles for Chef products

* Chef Infra Server: `chef-server-ctl gather-logs`
* Chef Automate v1: `automate-ctl gather-logs`
* Chef Automate v2: `chef-automate gather-logs`
* Chef Backend: `chef-backend-ctl gather-logs`

## Autocompletions

If you use the zsh shell you can add autocompletions for the `gatherlogs_report` command by adding the following
to your `~/.zshrc` config

```bash
source "/PATH/TO/gatherlogs/completions/gatherlogs_report.zsh"
```

## Local development


1. Download the source code

  ```bash
  git clone https://github.com/chef/gatherlogs-reporter
  git clone https://github.com/teknofire/glprofiles
  cd gatherlogs-reporter
  bundle
  ```

2. Add `gatherlogs-reporter/bin` to your path, put this in your `.bashrc` or the equivalent file for your shell.

  ```bash
  export PATH=$PATH:PATH/TO/gatherlogs-reporter/bin;
  ```

3. Run the reporter

  ```bash
  GL_DEV=true gatherlogs_report -p PATH/TO/LOGS
  ```
