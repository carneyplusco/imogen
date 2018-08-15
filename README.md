# collection-image-processor

## Requirements

1. Elixir 1.6+

## Setup

1. Run `mix deps.get` to install Elixir dependencies
1. Add SSH credentials for the EMu server to `config/dev.exs`

## Processing images

Run `mix Images.Update "path/to/json_file.json" "path/to/output/directory"`

> **Note**: directories that are not found in the JSON input file <u>will be deleted</u> from the output directory

## Syncing images

Run `mix Images.Sync "path/to/images/directory" "S3 bucket name"`
