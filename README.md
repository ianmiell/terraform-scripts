
Typical command to extract state using terraforming:

```
docker run \
    --rm \
    --name terraforming \
    -e AWS_REGION=us-east-1 
    -v ~/.aws:/root/.aws quay.io/dtan4/terraforming:latest
    terraforming vpc --profile default
```
