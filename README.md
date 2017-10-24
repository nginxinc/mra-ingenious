# ingenious

Ingenious is a photo-sharing demo app created by NGINX to show the Fabric Model approach to application development. The app is designed to allow the user to login to a personalized account, and then store, view and delete their own pictures. It also includes a blog in which users can view the latest news and updates within the application.

![Fabric Model from Microservices Reference Architecture](Fabric-Model_NGINX-Microservices-Reference-Architecture.png)

The Ingenious Application is built with microservices and utilizes their inherent benefits to generate a robust, stable, independent, polyglot environment.

Specifically, the app is designed using the Fabric Model - the most sophisticated architecture in the [MRA](https://www.nginx.com/blog/microservices-reference-architecture-nginx-fabric-model/) - to configure its services. Included in this configuration is an instance of NGINX running in every docker container. This allows for increased security without the typical decreased speed of communication between services. After an initial TLS/SSL handshake, a connection is then established and is able to be reused without any further overhead.

The Fabric Model suggests a new method of application development. Because NGINX Plus is running on both ends of every connection, capabilities of each service become a function of the app's network rather than capabilities of specific services or servers. NGINX Plus allows this network to be persistent, fast, and stable.

![Microservice Reference Architecture diagram of services](diagram-microservices-reference-architecture-850x600.png)

The ingenious application employs seven different services in order to create its functionality.

Pages is the foundational service built in Php upon which the other services provide functionality. Pages makes calls directly to user-manager, album-manager, content-service, and uploader.

User-manager is built completely using Python and backed by DynamoDB. It's use is to store and modify user information, allowing the app a login system. Login is done with Google and Facebook through OAuth, but also includes a system for local login when testing the system.

Album-manager is built using Ruby and backed by MySQL, and allows the user to upload albums of multiple images at once. Album-manager makes calls to the uploader service and therefore the resizer to upload and modify images specified by the user.

The Uploader service is built using Javascript and is used to upload images to an S3 bucket. Uploader then makes calls to the Resizer service with the previously generated id of the image within S3, and Resizer then makes copies of the image with size "Large", "Medium", and "Thumbnail".

Content-service is built in Go and backed by RethinkDB. The Content-service is responsible for ---

AuthProxy is a python app that utilizes Redis' capabilities as a caching server. Making direct connections to both pages and user-manager, AuthProxy is used to validate the user's identity. It also serves as the gateway into the application, acting as the only public-facing service within the application.