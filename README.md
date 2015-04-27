# BOSH Release for [Stardog](http://stardog.com)

## TODO

Bugs:

slf4j package in stardog-node should be configured to use log4j

## Usage

To use this bosh release, first upload it to your bosh:

```
bosh target BOSH_HOST
git clone https://github.com/complexible/stardog-release.git
cd stardog-release
bosh upload release releases/stardog-1.yml
```

Where `BOSH_HOST` is the IP/hostname of your BOSH (Lite) deployment.

For [bosh-lite](https://github.com/cloudfoundry/bosh-lite), you can quickly create a deployment manifest & deploy a cluster:

```
templates/make_manifest warden
bosh -n deploy
```

For AWS EC2 you need to pass in the network parameters for your VPC, so
you suffix this file path to the `make_manifest` command:

```
templates/make_manifest aws-ec2 my-network.yml
bosh -n deploy
```

Your `my-network.yml` file should look like:

```yaml
---
networks:
  - name: default
    type: dynamic
    dns: [10.0.0.6, 10.0.0.2]
    cloud_properties:
        subnet: YOUR_SUBNET_ID
```
