#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper qw(Dumper);

print `pwd` . "\n";

my %services;

$services{'resizer'} = { directory => "mra-photoresizer/nginx/ssl"}; 
$services{'uploader'} = {directory => "mra-photouploader/nginx/ssl", service1 => "resizer", service2 => "album-manager" };
$services{'content-service'} = {directory => "mra-content-service/nginx/ssl", service1 => "album-manager"   };
$services{'pages'} = {directory => "mra-pages/nginx/ssl", service1 => "user-manager", service2 => "album-manager", service3 => "content-service", service4 => "uploader"};
$services{'album-manager'} =  {directory => "mra-album-manager/nginx/ssl", service1 => "uploader"};
$services{'user-manager'} = {directory => "mra-user-manager/nginx/ssl", service1 => "album-manager" };
$services{'auth-proxy'} = {directory => "mra-auth-proxy/nginx/ssl", service1 => "user-manager", service2 => "album-manager", service3 => "content-service", service4 => "uploader", service5 => "pages", service6 => "resizer"};

# Generate the CA, Key and Cert for each service; 
print Dumper \%services;
foreach my $key (keys %services)
{
    my %service = %{$services{$key}};
    my $directory = "./" . $service{'directory'};
    print "We are dealing with $key and putting the CA certs and keys into the '$directory' directory\n";
    #print Dumper \%service;
    my $opensslCommand = "openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \\
        -subj  \"/C=US/ST=California/L=San Francisco/O=NGINX/OU=Professional Services/CN=$key\" \\
        -keyout $directory/$key" . "_ca.key \\
        -out $directory/$key". "_ca.pem";
    unless (-e "$directory/$key". "_ca.pem")
    {
        print $opensslCommand . "\n";
        `$opensslCommand`;
    }
    $opensslCommand = "openssl req -new \\
        -subj \"/C=US/ST=California/L=San Francisco/O=NGINX/OU=Professional Services/CN=$key\" \\
        -key $directory/$key" . "_ca.key \\
        -out $directory/$key" . ".csr";
    unless (-e "$directory/$key". ".csr")
    {
        print $opensslCommand . "\n";
        `$opensslCommand`;
    }
    $opensslCommand = "openssl x509 -req -days 365 \\
        -in $directory/$key" . ".csr \\
        -CA $directory/$key" . "_ca.pem \\
        -CAkey $directory/$key" . "_ca.key \\
        -set_serial 01 \\
        -out $directory/$key" . ".pem";
    unless (-e "$directory/$key". ".pem")
    {
        print $opensslCommand . "\n";
        `$opensslCommand`;
    }
    print "Done with $key \n";
}

print "Generate the Client CSRs, Key and Cert for each service, then copy over the service CA cert for authenticating on the client side\n";
foreach my $key (keys %services)
{
    print "Working on service: $key \n";
    my %service =  %{$services{$key}};
    my $serviceDirectory = "./" . $service{"directory"};
    my $serviceLength = keys %service;
    my $index = 1; #services start at service1;
    print "The number of services is " . ($serviceLength - $index) . "\n";
    while ($serviceLength > $index)
    {
        my $serviceIndex = "service" . $index;
        my $connectedService =  $service{$serviceIndex};
        my %connectedServiceInfo =  %{$services{$connectedService}};
        my $connectedServiceDirectory = "./" . $connectedServiceInfo{"directory"};
        my $opensslCommand = "openssl req -new \\
            -subj \"/C=US/ST=California/L=San Francisco/O=NGINX/OU=Professional Services/CN=$connectedService\" \\
            -key $connectedServiceDirectory/$connectedService" . "_ca.key \\
            -out $serviceDirectory/$connectedService" . "_client.csr";
        print "$opensslCommand\n";
        `$opensslCommand`;
        $opensslCommand = "openssl x509 -req -days 365 \\
            -in $serviceDirectory/$connectedService" . "_client.csr \\
            -CA $connectedServiceDirectory/$connectedService" . "_ca.pem \\
            -CAkey $connectedServiceDirectory/$connectedService" . "_ca.key \\
            -set_serial 01 \\
            -out $serviceDirectory/$connectedService" . "_client.pem";
        print $opensslCommand . "\n";
        `$opensslCommand`;
        my $copyCommand; 
        unless (-e "$connectedServiceDirectory/$key" . "_ca.pem")
        {
            $copyCommand = "cp $serviceDirectory/$key" . "_ca.pem $connectedServiceDirectory/$key" . "_ca.pem";
            `$copyCommand`;
        }
        unless (-e "$serviceDirectory/$connectedService" . "_ca.pem")
        {
            $copyCommand = "cp $connectedServiceDirectory/$connectedService" . "_ca.pem $serviceDirectory/$connectedService" . "_ca.pem";
            `$copyCommand`;
        }
        $index++;
    }
}
