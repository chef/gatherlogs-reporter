# Gatherlogs Inspec Profile

This is a proof of concept to see if using inspec to do some initial 
validation on gatherlog output from chef-products is viable.

Get inspec from: http://inspec.io

## Requirements

1. inspec (currently tested with Inspec 2.0+ but should work with Inspec v1
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

Some aliases to reduce the amount of typing

```bash
# check chef-server gather-logs
alias inspec_chefserver="inspec exec /PATH/TO/REPO/chef-server"
# check automate gather-logs
alias inspec_automate="inspec exec /PATH/TO/REPO/automate"
```

