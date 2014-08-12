package CGPReporter;

use Dancer ':syntax';
use Dancer::Request::Upload;
use Data::Dumper;

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

get '/upload' => sub {
    
    template( 'upload.tt' );

};

post '/select_date' => sub {

    my ( $error_msg, $is_complete );

    if ( $^O ne 'MSWin32' ) {
        $dates = [ 'Apr-13', 'Jun-13' ];
    }
    else {

        my $uploads_dir = "$FindBin::Bin/../public/uploads";
        
        my $file = request->upload('uploadedFile');
        
        my $content = $file->content();
        my $file_path = $uploads_dir . '/' . $file->filename;

        info "Copying uploaded file to: $file_path";

        $file->copy_to( $file_path );

        my $cgp_upload = CGPUpload->new( file_name => $file_path );

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

    debug "Dates: " . Dumper $dates;

    my $vars = { dates    => $dates
               , error    => $error_msg
               , complete => $is_complete };

    template( 'select_date.tt', $vars );
  
};

post '/process_date' => sub {

    my ( $error_msg, $is_complete, $exit_code );

    debug "Running CGPInsert with date: " . param 'date_to_upload';

    my $cgp_insert = CGPInsert->new( date => params->{ 'date_to_upload' } );

    eval {
        $exit_code = $cgp_insert->insertData();
    };

    if ( $@ ) {
        $error_msg = 'There was an error inserting the data'
    }
    else {
        $is_complete = 1 ;
    }

    my $vars = { error    => $error_msg
               , complete => $is_complete };

    template( 'processed_date.tt', $vars );

};

true;
