#!C:\perl\stawberry\perl\bin\perl.exe

use warnings;
use strict;

use 5.018;

use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use Carp;

use CGPUpload;

my $file_name;

GetOptions( "file=s" => \$file_name ) 
    or die ("Error in command line arguments");

die "File name not given -file" unless ( $file_name );

if ( $^O ne 'MSWin32' ) {
    croak "Cannot run on $^O platform";
} ;

my $cgp_upload = new CGPUpload( file_name => $file_name );

my $dates = $cgp_upload->uploadCGP();

print Dumper $dates;