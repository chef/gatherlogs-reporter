# Building hab pkg

This is the instructions for building and promoting the hab pkg

##

```
hab studio enter
build
# test the build
sup-log &
hab svc unload will/grese
hab svc load will/grese
# upload and promote
source results/last_build.env; hab pkg upload results/$pkg_artifact
source results/last_build.env; hab pkg promote $pkg_ident stable
```
