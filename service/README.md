# Gather-logs REporter SErvice

Quick Sinatra app to accept remote requests to parse gather-log bundles

## Requirements

* Ruby (2.5+)
* Bundler
* Zendesk account info
* Habitat (habitat.sh) for running in production and building the packages

## Installation for development

```
git clone REPOURL grese
cd grese
bundle install
```

#### Configure environment variables

Setup `.env` with the necessary variables for zendesk and the required API token.

```
export ZENDESK_URL=https://getchef.zendesk.com/api/v2
export ZENDESK_USER=<ZENDESK_USERNAME>
export ZENDESK_TOKEN=<ZENDESK_API_TOKEN>
export AUTH_TOKEN=<RANDOM_AUTHTOKEN_FOR_REQUEST>
```

#### Start the local service

```
source .env; bin/server
```

## Deploying to production

1. Install habitat on the system (https://habitat.sh)

2. Create habitat `config.toml`

  ```
  [server]
  auth_token = "SOMERANDOMTOKEN"
  zendesk_url = "https://getchef.zendesk.com/api/v2"
  zendesk_user = "someuser@chef.io"
  zendesk_token = ""
  ```

3. Install the package and setup the service

  ```
  hab pkg install will/grese
  hab svc load will/grese
  ```

4. Apply the Config

  ```
  hab config apply grese.default $(date '+%s') config.toml
  ```

5. Update the zendesk trigger for the gatherlogs reporter to point to the new domain and auth_token.
