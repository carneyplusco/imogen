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

Run `mix Images.Sync "path/to/images/directory" "S3 bucket name" "profile"`

`profile` coresponds to an existing AWS access configuration, most likely stored in `~/.aws/credentials` ([More info here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html))

Optionally add `"dryrun"` as the last argument to see an output of the proposed changes to S3 before committing them.

> **Note**: existing entries in S3 that are not found in the input directory <u>will be deleted</u> from the S3 bucket
