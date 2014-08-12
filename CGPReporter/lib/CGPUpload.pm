package CGPUpload;

use Moose;
use MooseX::Method::Signatures;

use Dancer ':syntax';

use Data::Dumper;
use Carp;
use JSON qw( );

use CGPUpload::Reader;
use CGPUpload::Parser;

has 'file_name'      => ( is => 'ro' );
has 'root_dir'       => ( is => 'rw' );
has 'cgp_table_text' => ( is => 'rw' );
has 'cgp_hash'       => ( is => 'rw' );
has 'METADATA_FILE'  => ( is => 'rw' );
has 'JSON_OUT_FILE'  => ( is => 'rw' );
has 'CGP_TEXT_FILE'  => ( is => 'rw' );

method uploadCGP( :$file_name ) {

    debug "Initiating CGPUploader";

    my $root_dir = "$FindBin::Bin/..";
    $self->root_dir( $root_dir );

    $self->METADATA_FILE ( "$root_dir/database/table_metadata.json" );
    $self->JSON_OUT_FILE ( "$root_dir/public/data/table_data.json"  );
    $self->CGP_TEXT_FILE ( "$root_dir/public/data/cgp_text.txt"     );

    $self->_readWordFile();
    $self->_readMetadata();
    $self->_parseCGPData();
    $self->_writeJSON();

    my $dates = $self->_get_cgp_dates();

    info 'Complete.';

    return $dates;
}

##############################################################################
# Read CGP using CGPParser
##############################################################################
method _readWordFile() {
    
    my $file_name = $self->file_name();

    info "Reading CGP: $file_name";

    my $cgp_reader = new CGPUpload::Reader( file_name => $file_name );

    $cgp_reader->open_word_doc();
    my @cgp_table_text = @{ $cgp_reader->get_cgp_tables() };

    unless ( @cgp_table_text ) {
        error "Unable to read Word doc";
    }

    $self->cgp_table_text( \@cgp_table_text );

    $cgp_reader->write_to_txt_file( file_data_text => $self->CGP_TEXT_FILE );

    info 'CGP text written to ' . $self->CGP_TEXT_FILE;

}

##############################################################################
# Get Metadata from JSON
##############################################################################
method _readMetadata() {

    info 'Getting metadata from JSON file...';

    my $json_text = do {
        open( my $json_fh, "<:encoding(UTF-8)", $self->METADATA_FILE )
            or croak ( 'Can\'t open ' . $self->METADATA_FILE . ":$!" );
        local $/;
        <$json_fh>
    };

    my $json = JSON->new;
    $self->cgp_hash( $json->decode( $json_text ) );

}

##############################################################################
# Parse CGP data
##############################################################################
method _parseCGPData() {

    my $cgp_hash   = $self->cgp_hash();
    my @table_text = @{ $self->cgp_table_text() };
    info 'Parsing data in text file...';

    my $table_data_parser = new CGPUpload::Parser(
                               table_text => \@table_text
                             , cgp_hash   => $cgp_hash
    );

    my $cluster_details  = $table_data_parser->get_cluster_details();

    if ( $cluster_details ) {
        $cgp_hash->{ 'cluster_details' }->{ 'data' } = $cluster_details;
        delete $cgp_hash->{ 'cluster_details' }->{ 'text' };
    }
    else {
        error "Could not process cgp details";
        exit 1;
    }

    my $table_hash = $cgp_hash->{ 'tables' };

    foreach my $table_number ( keys %{ $table_hash } ) {

        info "Processing data for table $table_number";

        my $table_data
              = $table_data_parser->get_table_data( table_number => $table_number );

        if ( $table_data ) {
            $table_hash->{ $table_number }->{ 'data' } = $table_data;
            delete $cgp_hash->{ 'tables' }->{ $table_number }->{ 'text' };
        }
        else {
            error "Could not process table $table_number";
            exit 1;
        }
    }

    info "Word document parsed successfully";

}

method _get_cgp_dates() {
    
    my $cgp_hash = $self->cgp_hash();

    # TODO: This is a really basic solution for now
    #
    my @dates = keys %{ $cgp_hash->{'tables'}->{'1'}->{'data'} };
    return \@dates;

}

##############################################################################
# Write data to JSON file
##############################################################################
method _writeJSON() {

    my $cgp_hash   = $self->cgp_hash();

    my $json = JSON->new;
    my $json_text = $json->encode( $cgp_hash );

    open my $json_fh, ">", $self->JSON_OUT_FILE;
    print $json_fh $json->pretty->encode( $cgp_hash );
    close $json_fh;

    info 'JSON successfully written to ' . $self->JSON_OUT_FILE;
}

no Moose;

__PACKAGE__->meta->make_immutable;