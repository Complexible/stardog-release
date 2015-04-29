# BOSH Release for [Stardog](http://stardog.com)

This [BOSH](http://bosh.io) release currently supports AWS and Bosh Lite deployments.

## Usage

First, make sure to install the [BOSH Command Line Interface](https://bosh.io/docs/bosh-cli.html)
and [`spiff`](https://github.com/cloudfoundry-incubator/spiff#installation).

#### AWS

To use this BOSH release on AWS, follow the next steps:

1. First, set up MicroBOSH on [AWS](https://bosh.io/docs/deploy-microbosh-to-aws.html).
	Note: when you set up your security group permissions, remember to open ports
	5820, 5821, 2888, and 3888, or whichever you choose for your Stardog Cluster.
2. Target your BOSH Director instance on AWS, and log in using `admin` for user and password.
    
		$ bosh target BOSH_HOST
		$ bosh login
		Your user: admin
		Enter password: *****

	Where `BOSH_HOST` is the IP/hostname of your BOSH (Lite) deployment.

3. Clone this project and `cd` to it.

		$ git clone https://github.com/complexible/stardog-release.git
		$ cd stardog-release

4. Place your license file in `jobs/stardog/templates/license/`.
5. Create a new release:
		
		$ bosh create release  --name stardog --version 3.0.1 --force

	This step will download the necessary binaries from an S3 blobstore and put
	them within this repository.
6. Upload your release to your BOSH Director

		$ bosh upload release

	This step will transfer the release scripts along with the binaries to your
	BOSH Director instance on EC2.
7. Create a manifest for your deployment
	
	1. First, create a configuration file to describe your AWS setup. Your `my-network.yml` file should look like:

		```yaml
		---
		networks:
  		- name: default
		    type: dynamic
		    dns: [10.0.0.6, 10.0.0.2]
		    cloud_properties:
		        subnet: YOUR_SUBNET_ID
		meta:
		  stardog:
		    instances: 3
		```

		Where you can specify the number of Stardog instances and the type of network
		according to the [BOSH CPI](http://bosh.io/docs/aws-cpi.html).

	2. Next, create a manifest for your deployment using the `make_manifest` script:
	
		```
		$ ./templates/make_manifest aws-ec2 my-network.yml
		```
	This will generate a manifest file by merging your configuration with the defaults.

8. Now you're ready to deploy:

	```
	$ bosh deploy
	```

#### Warden

In order to deploy to BOSH Lite – a local, development environment – you need the following:

1. Install BOSH Lite following the instructions in
the project's [`README`](https://github.com/cloudfoundry/bosh-lite#install-bosh-lite)
2. Start `vagrant` with the `virtualbox` provider per the [instructions](https://github.com/cloudfoundry/bosh-lite#using-the-virtualbox-provider).
3. Upload the Warden stemcell to your BOSH Lite Director:

		$ bosh upload stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent

4. Create a release by following the steps 4, 5, and 6 from the AWS deployment.
5. Create a manifest for your deployment:

	```
	$ templates/make_manifest warden
	$ bosh -n deploy
	```

6. Now you're ready to deploy:

	```
	$ bosh deploy
	```

## Troubleshooting

TODO

### TODO

slf4j package in stardog-node should be configured to use log4j
