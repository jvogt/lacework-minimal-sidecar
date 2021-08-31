# lacework-minimal-sidecar
Minimal Docker Image for Lacework Sidecar (for use on AWS Fargate).  This Docker image is intended to be loaded as a volume where the `/shared` directory contains the lacework agent, the sidecar startup script, and an optional ca-certificates.crt file.

Can be used directly from Dockerhub (!!! For TESTING !!!) or use this code to build and maintain on your own until supported by Lacework.

[`jdvogt/lacework-minimal-sidecar:latest`](https://hub.docker.com/r/jdvogt/lacework-minimal-sidecar)


## How to use
1. Acquire a Lacework Access token from your Lacework console
1. Set the `LaceworkAccessToken` environment variable in your Fargate task or in your k8s manifest / helm chart (for EKS Fargate)
1. Decide if you want to load this image as a volume at run-time or build-time.  (see below)
1. Decide if you want to execute Lacework datacollector by prepending your `CMD`, or by using Lacework as an `ENTRYPOINT` script. (see below)

## Deciding to load image at run-time or build-time
### Run-time
Fargate supports adding additional containers to your task definitions.  They do not have to run, they can exist as a volume to your application container.

See [example-task-def.yaml](example-task-def.yaml) for an example of this

Pros:
- Do not have to change existing docker images
Cons:
- Need to modify all task definitions
- Need to set `ENTRYPOINT` / `CMD` in task definition (cannot use whats built into your application containers)

### Build-time
A `Dockerfile` supports the use of a "multi-stage build" to load files from one container into your application containers.  You can use this Docker image to source for the datacollector binary and sidecar script at build-time.

See [example-customer-Dockerfile](example-customer-Dockerfile) for an example of this

Pros:
- Simplify task definitions at Fargate
- Possible to embed into a base image consumable by all teams using Docker
Cons:
- Need to modify all `Dockerfiles` to embed, unless using a common internally-managed base docker image (pro tip: use a common entrypoint and execute the Lacework sidecar script here)

## Deciding how to execute the datacollector
This image contains a script (`lacework.sh`) to start the Lacework agent.  It will start the agent in background mode, but can also work as an `ENTRYPOINT` where it executes whatever follows (Docker will combine `ENTRYPOINT` and `CMD` at run-time).

### Example of prepending `CMD`:
```
CMD ["sh", "-c", "/shared/lacework.sh && nginx -g \"daemon off;\""]
```

Note that everything following `"-c"` is in one string and not broken up.  This is because `sh -c` takes input as a single argument to execute

Pros:
- Retain existing `ENTRYPOINT`
Cons:
- Sometimes difficult to escape shell characters

### Example of using `ENTRYPOINT`
(Note: you must set `LaceworkRunAsEntrypoint="true"` when using sidecar script as `ENTRYPOINT`)

```
ENTRYPOINT ["/shared/lacework.sh"]
CMD ["nginx", "-g", "daemon off;"]
```

Pros:
- Much more docker-like.  `CMD` works as expected
Cons:
- Cannot use existing `ENTRYPOINT`
- Will start datacollector even when using docker exec

## Reference:
### Environment Variables Supported by `lacework.sh`
| Environment Variable | Description |
| --- | --- |
| `LaceworkAccessToken="..."` | (Required) |
| `LaceworkDebug="true"` | (Optional, will tail datacollector.log) |
| `LaceworkAddRootCerts="true"` | (Optional, creates /etc/ssl/certs/ca-certificates.crt) |
| `LaceworkRunAsEntrypoint="true"` | (Optional, use if setting lacework.sh as ENTRYPOINT in docker. This script will execute whatever is presented in CMD) |
