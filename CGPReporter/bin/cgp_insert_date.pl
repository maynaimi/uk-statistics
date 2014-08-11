#!C:\perl\stawberry\perl\bin\perl.exe

use warnings;
use strict;

use 5.018;

use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;

use CGPInsert;

my $date;

GetOptions( "date=s" => \$date ) 
    or die ("Error in command line arguments");

die "Date not given -date" unless ( $date );

my $cgp_insert = new CGPInsert( date_to_upload => $date );

my $exit_code = $cgp_insert->insertCGPDate();

print Dumper $exit_code;