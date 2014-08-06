#!C:\perl\stawberry\perl\bin\perl.exe

use warnings;
use strict;

use 5.018;

use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;

use CGPUpload;


my $file_name;

GetOptions( "file=s" => \$file_name ) 
    or die ("Error in command line arguments");

die "File name not given" unless ( $file_name );

my $cgp_upload = new CGPUpload( file_name => $file_name );

my $dates = $cgp_upload->uploadCGP();

print Dumper $dates;