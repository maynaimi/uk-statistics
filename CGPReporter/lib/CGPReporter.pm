package CGPReporter;
use Dancer ':syntax';

use CGPInsert;

our $VERSION = '0.1';

my  $dates;

BEGIN {
    if ( $^O eq 'MSWin32' ) {
        require 'CGPUpload.pm';
        CGPUpload->import;
    }
}

get '/' => sub {
    template 'index';
};

any ['get', 'post'] => '/upload' => sub {
 
    my ( $error_msg, $is_complete );

    if ( request->method() eq "POST" ) {
        
        if ( $^O ne 'MSWin32' ) {
            $dates = [ 'Apr-13', 'Jun-13' ];
        }
        else {

            my $file_name = 'C:\Users\May\Documents\uk-statistics\CGPReporter\public\data\cgp\Essex2.docx';
            my $cgp_upload = CGPUpload->new( file => $file_name );
        
            #my $cgp_upload = CGPUpload->new( file => $params->file_name );

            eval {
               $dates = $cgp_upload->uploadCGP();
            };
 
            if ( $@ ) {
                $error_msg = 'There was an error uploading the file'
            }
            else {
                $is_complete = 1 ;
            }
        }
    }

    template( 'upload.tt' );
 
};

any ['get', 'post'] => '/select_date' => sub {
 
    my ( $error_msg, $is_complete, $exit_code );

    if ( request->method() eq "POST" ) {
        
        my $cgp_insert = CGPInsert->new( date => params->{ 'date' } );

        eval {
            $exit_code = $cgp_insert->insertData();
        };
 
        if ( $@ ) {
            $error_msg = 'There was an error inserting the data'
        }
        else {
            $is_complete = 1 ;
        }
    }

    $dates = [ 'Apr-13', 'Jun-13' ];
    my $vars = { dates => $dates };

    template( 'select_date.tt', $vars );
 
};

# get '/select_date' => sub {
# 	template 'select_date';
# 	# my @dates = ('Apr-2013', 'Jul-2013');
#     # template 'select_date', \@dates;
# };

true;
