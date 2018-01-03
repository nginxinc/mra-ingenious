# Ingenious
_Ingenious_ is a photo-sharing demo app created by NGINX to show the Fabric Model approach to application development. The app is designed to allow the user to login to a personalized account, and then store, view and delete their own pictures. It also includes a blog in which users can view the latest news and updates within the application.

![Fabric Model from Microservices Reference Architecture](Fabric-Model_NGINX-Microservices-Reference-Architecture.png)

The _Ingenious_ application is built with microservices and utilizes their inherent benefits to generate a robust, stable, independent, polyglot environment.

Specifically, the app is designed using the [Fabric Model](https://www.nginx.com/blog/microservices-reference-architecture-nginx-fabric-model/) - the most sophisticated architecture in the [MRA](https://www.nginx.com/blog/introducing-the-nginx-microservices-reference-architecture/) - to configure its services. Included in this configuration is an instance of NGINX running in every docker container. This allows for increased security without the typical decreased speed of communication between services. After an initial TLS/SSL handshake, a connection is then established and is able to be reused without any further overhead.

The Fabric Model suggests a new method of application development. Because NGINX Plus is running on both ends of every connection, capabilities of each service become a function of the app's network rather than capabilities of specific services or servers. NGINX Plus allows this network to be persistent, fast, and stable.

![Microservice Reference Architecture diagram of services](diagram-microservices-reference-architecture-850x600.png)

The _Ingenious_ application employs seven different services in order to create its functionality.

Pages is the foundational service built in PHP upon which the other services provide functionality. Pages makes calls directly to User Manager, Album Manager, Content Service, and Uploader.

User Manager is built completely using Python and backed by DynamoDB. It's use is to store and modify user information, allowing the app a login system. Login is done with Google and Facebook through OAuth, but also includes a system for local login when testing the system.

Album Manager is built using Ruby and backed by MySQL, and allows the user to upload albums of multiple images at once. Album Manager makes calls to the Uploader service and therefore the Resizer to upload and modify images specified by the user.

The Uploader service is built using Javascript and is used to upload images to an S3 bucket. Uploader then makes calls to the Resizer service with the previously generated id of the image within S3, and Resizer then makes copies of the image with size "Large", "Medium", and "Thumbnail".

Content Service is built in Go and backed by RethinkDB. The Content Service provides, retrieves, and displays content for the NGINX _Ingenious_ application

Auth Proxy is a Python app that utilizes Redis' capabilities as a caching server. Making direct connections to both Pages and User Manager, Auth Proxy is used to validate the user's identity. It also serves as the gateway into the application, acting as the only public-facing service within the application.

## Quick start
You can clone all the repositories of the NGINX _Ingenious_ application using the command below:
```
git clone --recursive https://github.com/nginxinc/mra-ingenious.git
```

There are detailed instructions for building the service below, and in order to get started quickly, you can follow these simple 
instructions to quickly build the image.

0. (Optional) If you don't already have an NGINX Plus license, you can request a temporary developer license 
[here](https://www.nginx.com/developer-license/ "Developer License Form"). If you do have a license, then skip to the next step. 
1. Copy your licenses to the **<repository-path>/<mra-service>/nginx/ssl** directory for all the services
2. Modify your _hosts_ file to include fake-s3. It should look like:
    ```
    127.0.0.1   fake-s3
    ``` 
3. Go to the **mra-ingenious** directory and run the command `docker-compose up`.

At this point, you will have the _Ingenious_ application running locally. You can access it in your browser with the url `https://localhost/`.

To build customized images for the different services or to set other options, please check the specific README for each service.

Three docker compose files are included with this service:
- [docker-compose.yaml](docker-compose.yaml): to run in containers on the machine where the repository has been cloned
- [docker-compose-k8s.yaml](docker-compose-k8s.yaml): to run on Kubernetes
- [docker-compose-dcos.yaml](docker-compose-dcos.yaml): to run on DC/OS
