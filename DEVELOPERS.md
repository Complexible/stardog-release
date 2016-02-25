## Project layout

There are four different parts that make up this project:

* `jobs`: under this folder are located scripts for starting and monitoring
the applications within a Stardog Cluster (ZooKeeper, HAProxy, Stardog). Each
component will have a separate sub folder with scripts and configuration templates
for starting up each job.

* `packages`: in this folder you'll find specifications of the blobs that jobs
will use for operation, and installation scripts for provisioning machines in the cluster.
Typically these binaries are Stardog, a custom JDK, and helper scripts.

* `src`: in this folder are located some scripts that are common to more than one
component and they will be installed as described in the corresponding package spec.

* `templates`: here are the networking rules that interact with BOSH's CPI.

Additionally, you'll have to make sure that the file `config/final.yml` points to the
S3 bucket that contains this release's blobs and that `config/blobs.yml` is up to
date wrt the blobs described in `packages`. Make sure to never add `config/private.yml`
to version control.

## Updating blobs

First, make sure you have the credentials set up in `config/private.yml`:

```
blobstore:
  s3:
    access_key_id: <the access key id>
    secret_access_key: <secret key>
```

Next, using the `bosh` CLI add the blob to this project, e.g.:

```
bosh add blob /path/to/stardog-4.x.zip stardog
```

Which will copy the `stardog-4.x.zip` file to `blobs/stardog`.

Finally, you should update any references to that file in `packages/` and
`jobs/` that may be necessary.
