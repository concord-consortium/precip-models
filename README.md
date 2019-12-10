
This repo is only for keeping source files.  'Deployment' isn't automated.
The `add-css.sh` script creates modified HTML files in `./output/`
Files from `./input` are copied to `./output` and then CSS is added.
In the output HTML files most NetLogo web chrome to be hidden.
The final URLS are writen to `./index.txt`

## From NetLogo to HTML to S3:
1. Export the NetLogo models from `./netlogo` to HTML files in
`./input`. I don't think we can automate this, we just need to open the files in
NetLogo.

2. Run `add-css.sh` to process all the files in `./input` and generate files in
`./output`.
3. Manually copy `./output` to S3 bucket `models-resources/precip-models`


To 'deploy' these models, copy files from `output` to the S3 bucket named:
`models-resources/precip-models`

You will probably want to invalidate the cloudfront cache manually, because the min TTL is 24 hours.
TODO: It would be cool to figure out a way to automatically deploy these and invalidate cloud front.


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

## WARNING:  NetLogo V6.1.1 doesn't seem to enable importing of images...
As of 2019-12-10 the latest versions of NetLogo have poor image import support.
I was able to use version 6.0.4 to build / export web versions.

