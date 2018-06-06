#!/bin/bash

declare -A services
declare -A serviceInfo

services["resizer"]=arr+=( ["directory"]="mra-photoresizer/nginx/ssl")
services["uploader"]=arr+=( ["directory"]="mra-photouploader/nginx/ssl" ["service1"]="resizer"  ["service2"]="album-manager" )
services["content-service"]=arr+=( ["directory"]="mra-content-service/nginx/ssl" ["service1"]="album-manager"   )
services["pages"]=arr+=( ["directory"]="mra-pages/nginx/ssl" ["service1"]="user-manager"  ["service2"]="album-manager" ["service3"]="content-service" ["service4"]="uploader")
services["album-manager"]=arr+=( ["directory"]="mra-album-manager/nginx/ssl" ["service1"]="uploader")
services["user-manager"]=arr+=( ["directory"]="mra-user-manager/nginx/ssl" ["service1"]="resizer"  ["service2"]="album-manager" )
services["auth-proxy"]=arr+=( ["directory"]="mra-auth-proxy/nginx/ssl" ["service1"]="user-manager"  ["service2"]="album-manager" ["service3"]="content-service" ["service4"]="uploader"  ["service5"]="pages" ["service6"]="resizer")

# Generate the CA, Key and Cert for each service
for key in ${!services[@]}; do
    echo ${key} ${services[${key}]}
    serviceInfo =  ${services[${key}]}
    cd ${serviceInfo["directory"]}
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
     -subj  "/C=US/ST=California/L=San Francisco/O=NGINX/OU=Professional Services/CN=${key}" \
     -keyout ${key}_ca.key \
     -out ${key}_ca.pem
    openssl req -new \
     -subj "/C=US/ST=California/L=San Francisco/O=NGINX/OU=Professional Services/CN=${key}" \
     -key ${key}_ca.key \
     -out ${key}.csr
    openssl x509 -req -days 365 -in ${key}.csr -CA ${key}_ca.pem -CAkey ${key}_ca.key -set_serial 01 -out ${key}.pem
done

echo "Length of services= ${#services[@]}"

# Generate the Client CSRs, Key and Cert for each service, then copy over the service CA cert for authenticating on the client side
for key in ${!services[@]}; do
    echo ${key} ${services[${key}]}
    serviceInfo =  ${services[${key}]}
    serviceDirectory = ${serviceInfo["directory"]}
    cd ${serviceDirectory}
    serviceLength = ${#serviceInfo[@]}
    index = 1 #services start at service1
    while [ $serviceLength -lt $index ]
        connectedService =  ${serviceInfo[service${index}]}
        connectedServiceInfo =  ${services[${connectedService}]}
        connectedServiceDirectory ${serviceInfo["directory"]}
        openssl req -new \
            -subj "/C=US/ST=California/L=San Francisco/O=NGINX/OU=Professional Services/CN=${connectedService}" \
            -key ../../../${connectedServiceDirectory}/${connectedService}_ca.key \
            -out ../../../${connectedServiceDirectory}/${connectedService}_client.csr
        openssl x509 -req -days 365 \
            -in resizer_client.csr \
            -CA ${key}_ca.pem \
            -CAkey ${key}_ca.key \
            -set_serial 01 \
            -out ../../../${connectedServiceDirectory}/${key}_client.pem
        cp ${key}_ca.pem ../../../${connectedServiceDirectory}/${key}_ca.pem
        ((index++))
    done
done
