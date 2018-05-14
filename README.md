# Gatherlogs InSpec Profile

This is a proof of concept to see if using InSpec to do some initial
validation on gatherlog output from chef-products is viable.

Get InSpec from: http://inspec.io

## Requirements

1. inspec (currently tested with InSpec v2 but should work with InSpec v1
2. git clone of this repo

## Usage

The basic usage is that you will need to be in the directory with the
expanded gather-logs tar file. You should be running this in the same
directory as you would find the `installed-packages.txt` or
`platform_version.txt` files.

Run `inspec` like this to validate the gather-log files in the current directory.

```
# to check gather-logs from chef-server use
inspec exec /PATH/TO/REPO/chef-server
# to check gather-logs from automate use
inspec exec /PATH/TO/REPO/automate
# etc.....
```

### Large diff outputs make things ugly

So some tests will cause a large diff output to print to the screen and makes it
very difficult to tell what is failing.

You can get around this problem by running the commands like this to get just the bare minimum:

```bash
$ inspec_automate --reporter json-min | jq ".controls[] | { id, status, code_desc }"
{
  "id": "automate.gatherlogs.missing-data-collector-token",
  "status": "failed",
  "code_desc": "File var/log/delivery/delivery/console.log content should not match /Data Collector request made without access token/"
}
{
  "id": "automate.gatherlogs.missing-data-collector-token",
  "status": "failed",
  "code_desc": "File var/log/delivery/delivery/current content should not match /Data Collector request made without access token/"
}
```

### Or possibly to only see the failed controls with messages

```bash
inspec_chefserver --reporter json-min | jq -r '.controls[] | { id, status, code_desc, message } | select( .status | contains("failed"))'
```

### Aliases cause typing is bad

Some aliases to reduce the amount of typing

```bash
# check chef-server gather-logs
alias inspec_chefserver="inspec exec /PATH/TO/REPO/chef-server"
# check automate gather-logs
alias inspec_automate="inspec exec /PATH/TO/REPO/automate"
```

## Example output

```
Profile: InSpec profile for Chef-Server generated gather-logs (chef-server)
Version: 0.1.0
Target:  local://

  ×  chef-server.gatherlogs.chef-server: check that chef-server is installed (1 failed)
     ✔  installed_packages should exist
     ×  installed_packages version should cmp >= "12.17.0"

     expected it to be >= "12.17.0"
          got: 12.15.8

     (compared using `cmp` matcher)

  ✔  chef-server.gatherlogs.disk_usage: check that the chef-server has plenty of free space
     ✔  "/" disk_usage used_percent should cmp < 100
     ✔  "/" disk_usage available should cmp > 10
     ✔  "/" disk_usage size should cmp > 40
  ✔  chef-server.gatherlogs.platform: check platform is valid
     ✔  platform_version content should not match /Platform and version are unknown/
  ×  chef-server.gatherlogs.reporting-with-2018-partition-tables: make sure installed reporting version has 2018 parititon tables fix
     ×  installed_packages version should cmp >= "1.7.10"

     expected it to be >= "1.7.10"
          got: 1.7.1

     (compared using `cmp` matcher)
```

## TODO

* [ ] It would be nice if we could test to see if `noexec` is set on `/tmp`
