
This repo is only for keeping source files.  'Deployment' isn't automated.

To 'deploy' these models, copy files to the S3 bucket named:
`models-resources/precip-models`

You will probably want to invalidate the cloudfront cache manually, because the min TTL is 24 hours.

The `add-css.sh` file causes certain NetLogo chrome to be hidden.

The deployed models can then be found on S3 webiste, at this URLS:

Alaska:
https://models-resources.concord.org/precip-models/lesson-4-ak.html
https://models-resources.concord.org/precip-models/lesson-5-ak.html
https://models-resources.concord.org/precip-models/precip-rule-ak.html

Alaska V2:
https://models-resources.concord.org/precip-models/lesson-4-ak-v2.html
https://models-resources.concord.org/precip-models/precip-rule-ak-v2.html


New England:
https://models-resources.concord.org/precip-models/lesson-4-ne.html
https://models-resources.concord.org/precip-models/lesson-5-ne.html
https://models-resources.concord.org/precip-models/precip-rule-ne.html

New England V2:
https://models-resources.concord.org/precip-models/lesson-4-ne-v2.html
https://models-resources.concord.org/precip-models/precip-rule-ne-v2.html

