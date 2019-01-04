
This repo is only for keeping source files.  'Deployment' isn't automated.

To 'deploy' these models, copy files to the S3 bucket named:
`models-resources/precip-models`

You will probably want to invalidate the cloudfront cache manually, because the min TTL is 24 hours.

The `add-css.sh` file causes certain NetLogo chrome to be hidden.