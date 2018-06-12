#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper qw(Dumper);

my $clean = $ARGV[0] || "0";
my $encryptionBits = "2048";
if ($clean eq "clean")
{
    print "Cleaning all of the mtls generated keys, certs and CSRs\n";
}
 
# The openssl CA commands assume a DB (index.txt) and a serial file (serial)
# These are reset every time you generate the certs, though you would want to preserve them 
`rm ./mtls/index.txt* ./mtls/serial* && touch ./mtls/index.txt && echo '01' > ./mtls/serial`;

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
    my $opensslCommand = "openssl req -new \\
        -newkey rsa:$encryptionBits -days 365 -nodes -x509 \\
        -subj  \"/C=US/ST=California/L=San Francisco/O=NGINX/OU=Professional Services/CN=$key" . "_ca\" \\
        -keyout $directory/$key" . "_ca.key \\
        -out $directory/$key". "_ca.pem";
    formatAndRun($opensslCommand, "$directory/$key". "_ca.pem");
    $opensslCommand = "openssl req -new \\
        -newkey rsa:$encryptionBits -nodes \\
        -subj \"/C=US/ST=California/L=San Francisco/O=NGINX/OU=Professional Services/CN=$key\" \\
        -keyout $directory/$key" . ".key \\
        -out $directory/$key" . ".csr";
    formatAndRun($opensslCommand, "$directory/$key". ".csr");
    $opensslCommand = "openssl x509 -req -days 365 \\
        -in $directory/$key" . ".csr \\ 
        -CA $directory/$key" . "_ca.pem \\
        -CAkey $directory/$key" . "_ca.key \\
        -set_serial 01 \\
        -out $directory/$key" . "_ss.pem";
    formatAndRun($opensslCommand,  "$directory/$key". "_ss.pem");
    my $outDirectory =  $service{'directory'};
    # the ca -out option requires that no "./" be prepended
    $opensslCommand = "openssl ca -batch \\
        -cert $directory/$key" . "_ca.pem \\
        -keyfile $directory/$key" . "_ca.key \\
        -config ./mtls/ca.conf  \\
        -out $outDirectory/$key" . ".pem \\
        -ss_cert $directory/$key" . "_ss.pem \\
        -infiles $directory/$key" . ".csr";
    formatAndRun($opensslCommand, "$outDirectory/$key" . ".pem");
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
        print "The connected service is: $connectedService \n";
        my %connectedServiceInfo =  %{$services{$connectedService}};
        my $connectedServiceName =  $service{$serviceIndex} . "_" . $key;
        my $connectedServiceDirectory = "./" . $connectedServiceInfo{"directory"};
        my $opensslCommand = "openssl req -new \\
            -subj \"/C=US/ST=California/L=San Francisco/O=NGINX/OU=Professional Services/CN=$connectedServiceName\" \\
            -newkey rsa:$encryptionBits -nodes \\
            -keyout $serviceDirectory/$connectedService" . "_client.key \\
            -out $serviceDirectory/$connectedService" . "_client.csr";
        formatAndRun($opensslCommand, "$serviceDirectory/$connectedService" . "_client.csr");

        $opensslCommand = "openssl x509 -req -days 365 \\
            -in $serviceDirectory/$connectedService" . "_client.csr \\
            -CA $connectedServiceDirectory/$connectedService" . "_ca.pem  \\
            -CAkey $connectedServiceDirectory/$connectedService" . "_ca.key \\
            -set_serial 01 \\
            -out $serviceDirectory/$connectedService" . "_client_ss.pem";
        formatAndRun($opensslCommand, "$serviceDirectory/$connectedService" . "_client_ss.pem");
        my $outDirectory =  $service{'directory'};
        # the ca -out option requires that no "./" be prepended
        
        $opensslCommand = "openssl ca -batch \\
            -cert $connectedServiceDirectory/$connectedService" . "_ca.pem \\
            -keyfile $connectedServiceDirectory/$connectedService" . "_ca.key \\
            -config ./mtls/ca.conf \\
            -out $outDirectory/$connectedService" . "_client.pem \\
            -ss_cert $serviceDirectory/$connectedService" . "_client_ss.pem \\
            -infiles $serviceDirectory/$connectedService" . "_client.csr";
        formatAndRun($opensslCommand, "$outDirectory/$connectedService" . "_client.pem");

        my $copyCommand = "cp $serviceDirectory/$key" . "_ca.pem $connectedServiceDirectory/$key" . "_ca.pem";
        formatAndRun($copyCommand, "$connectedServiceDirectory/$key" . "_ca.pem");
        $copyCommand = "cp $connectedServiceDirectory/$connectedService" . "_ca.pem $serviceDirectory/$connectedService" . "_ca.pem";
        formatAndRun($copyCommand, "$serviceDirectory/$connectedService" . "_ca.pem");
        $index++;
    }
}
cleanUpIntermediaryPems();

sub formatAndRun 
{
    my $command = $_[0];
    my $checkFile = $_[1] || "0";
    my $fileExists = 0;
    if (-e $checkFile)
    {
        $fileExists = "true";
    }
    $command =~ s/\\ *\n//g;
    $command =~ s/  +/ /g;
    if ($clean eq "clean")
    {
        #print "This the command we are extracting from: $command \n";
        my @files = ($command =~ m/(mra-.*?(?:.pem|.key|.csr))/g);
        $command = "rm ";
        foreach my $file (@files)
        {
            $file = "./$file";
            #print "This is the file to check: $file\n";
            if (-e $file)
            {
                $command .= $file . " ";
            }    
        }
        $fileExists = 0;
        if ($command eq "rm ")
        {
            $command = "echo 'No files to delete'";
        }
    }
    print $command . "\n";
    print "We are running the command: \n" if !$fileExists;
    unless ($fileExists)
    {
        `$command`;
    }
}

sub cleanUpIntermediaryPems
{
    #cleaning up the intermediary certs that openssl litters on the file system
    my $localDir = "./";
    
    print "Working Directory: $localDir \n";
    opendir my $dir, $localDir or die "Cannot open directory: $!";
    my @files = readdir $dir;
    my $rmList = "";
    foreach my $file (@files) 
    {
        # The intermediary files are in the format 01.pem with hex digits
        if($file =~ /..\.pem/)
        {
            $rmList .= "./$file ";
        }
    }
    print "Deleting these PEM files: $rmList\n";
    `rm $rmList`;
    closedir $dir;
}