package CGPUpload;

use Moose;
use MooseX::Method::Signatures;

use Data::Dumper;
use Carp;
use JSON;
use Log::Log4perl qw(:easy);

use CGPUpload::Reader;
use CGPUpload::Parser;

has 'file_name'      => ( is => 'ro' );
has 'root_dir'       => ( is => 'rw' );
has 'logger'         => ( is => 'rw' );
has 'cgp_table_text' => ( is => 'rw' );
has 'cgp_hash'       => ( is => 'rw' );
has 'METADATA_FILE'  => ( is => 'rw' );
has 'JSON_OUT_FILE'  => ( is => 'rw' );
has 'CGP_TEXT_FILE'  => ( is => 'rw' );

method uploadCGP( :$file_name ) {

    my $root_dir = "$FindBin::Bin/..";
    $self->root_dir( $root_dir );

    $self->METADATA_FILE ( "$root_dir/database/table_metadata.json" );
    $self->JSON_OUT_FILE ( "$root_dir/public/data/table_data.json"  );
    $self->CGP_TEXT_FILE ( "$root_dir/public/data/cgp_text.txt"     );

    $self->_initLogger();
    $self->_readWordFile();
    $self->_readMetadata();
    $self->_parseCGPData();
    $self->_writeJSON();

    my $dates = $self->_get_cgp_dates();

    return $dates;
}

##############################################################################
# Initiate Logger
##############################################################################
method _initLogger() {

    Log::Log4perl->init( $self->root_dir . '/conf/log4perl.conf');
    my $logger = Log::Log4perl->get_logger('CGP');

    $logger->info( 'Initialised logger...' );

    $self->logger( $logger );

}

##############################################################################
# Read CGP using CGPParser
##############################################################################
method _readWordFile() {
    
    my $file_name = $self->file_name();
    my $logger    = $self->logger();
    $logger->info( "Reading CGP: $file_name" );

    my $cgp_reader = new CGPUpload::Reader( file_name => $file_name
                               , logger    => $logger
    );

    $cgp_reader->open_word_doc();
    my @cgp_table_text = @{ $cgp_reader->get_cgp_tables() };

    unless ( @cgp_table_text ) {
        $logger->error( "Unable to read Word doc" );
    }

    $self->cgp_table_text( \@cgp_table_text );

    $cgp_reader->write_to_txt_file( file_data_text => $self->CGP_TEXT_FILE );

    $logger->info( 'CGP text written to ' . $self->CGP_TEXT_FILE );

}

##############################################################################
# Get Metadata from JSON
##############################################################################
method _readMetadata() {

    my $logger = $self->logger();
    $logger->info( 'Getting metadata from JSON file...' );

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
    my $logger     = $self->logger();
    $logger->info( 'Parsing data in text file...' );

    my $table_data_parser = new CGPUpload::Parser(
                               table_text => \@table_text
                             , cgp_hash   => $cgp_hash
                             , logger     => $logger
    );

    my $cluster_details  = $table_data_parser->get_cluster_details();

    if ( $cluster_details ) {
        $cgp_hash->{ 'cluster_details' }->{ 'data' } = $cluster_details;
        delete $cgp_hash->{ 'cluster_details' }->{ 'text' };
    }
    else {
        $logger->error( "Could not process cgp details" );
        exit 1;
    }

    my $table_hash = $cgp_hash->{ 'tables' };

    foreach my $table_number ( keys %{ $table_hash } ) {

        $logger->info( "Processing data for table $table_number" );

        my $table_data
              = $table_data_parser->get_table_data( table_number => $table_number );

        if ( $table_data ) {
            $table_hash->{ $table_number }->{ 'data' } = $table_data;
            delete $cgp_hash->{ 'tables' }->{ $table_number }->{ 'text' };
        }
        else {
            $logger->error( "Could not process table $table_number" );
            exit 1;
        }
    }

    $logger->info( "Word document parsed successfully" );

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

    my $logger = $self->logger();
    my $cgp_hash   = $self->cgp_hash();

    my $json = JSON->new;
    my $json_text = $json->encode( $cgp_hash );

    open my $json_fh, ">", $self->JSON_OUT_FILE;
    print $json_fh $json->pretty->encode( $cgp_hash );
    close $json_fh;

    $logger->info( 'JSON successfully written to ' . $self->JSON_OUT_FILE );

    $logger->info( "Complete." );
}



no Moose;

__PACKAGE__->meta->make_immutable;