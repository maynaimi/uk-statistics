package CGPReporter;
use Dancer ':syntax';

use CGPUpload;
use CGPInsert;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

any ['get', 'post'] => '/upload' => sub {
 
    my ( $error_msg, $is_complete );

    if ( request->method() eq "POST" ) {
        
        my $file_name = 'C:\Users\May\Documents\uk-statistics\CGPReporter\public\data\cgp\Essex2.docx';
        my $cgp_upload = CGPUpload->new( file => $file_name );
        
        #my $cgp_upload = CGPUpload->new( file => $params->file_name );
        my $dates;

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

    template( 'select_date.tt' );
 
};

true;
