package CGPInsert;

use Moose;
use MooseX::Method::Signatures;

use Dancer ':syntax';

use Data::Dumper;
use Carp;
use JSON qw();

use CGPInsert::InsertControl;

has 'date_to_upload' => ( is => 'rw' );
has 'root_dir'       => ( is => 'rw' );
has 'JSON_IN_FILE'   => ( is => 'rw' );
has 'DATABASE_PATH'  => ( is => 'rw' );
has 'cgp_hash'       => ( is => 'rw' );

method insertCGPDate( :$date_to_upload ) {

    debug "inside insertCGPDate";

    my $root_dir = "$FindBin::Bin/..";
    $self->root_dir( $root_dir );

    $self->JSON_IN_FILE  ( "$root_dir/public/data/table_data.json" );
    $self->DATABASE_PATH ( "$root_dir/database/cgp_database.db"    );

    $self->date_to_upload( $date_to_upload );

    $self->_readJSON();
    my $exit_code = $self->_insertData();
    
    info "Done.";

    return $exit_code;
}

##############################################################################
# Read JSON
##############################################################################
method _readJSON() {
    
    info 'Getting metadata from JSON file...';

    my $json_text = do {
        open( my $json_fh, "<:encoding(UTF-8)", $self->JSON_IN_FILE )
            or croak ( 'Can\'t open ' . $self->JSON_IN_FILE . ": $!" );
        local $/;
        <$json_fh>
    };

    my $json = JSON->new;
    $self->cgp_hash( $json->decode( $json_text ) );

}

##############################################################################
# Get Metadata from JSON
##############################################################################
method _insertData() {

    my $cgp_insert = new CGPInsert::InsertControl( 
                                database_path => $self->DATABASE_PATH );

    my $cluster_details = $cgp_insert->check_cluster_details( 
                cluster_details => $self->cgp_hash->{ 'cluster_details' } );

    my $cluster_data = $cluster_details->{ 'data' };
    my $cluster_name = $cluster_data->{ 'cluster'      };
    my $region       = $cluster_data->{ 'region'       };
    my $cluster_code = $cluster_data->{ 'cluster_code' };

    my $cgp_id = $cgp_insert->insert_cgp( date         => $self->date_to_upload
                                        , cluster_code => $cluster_code
                                        , region       => $region
    );

    if ( $cgp_id ) {

        $cgp_insert->insert_cgp_data( all_table_data => $self->cgp_hash->{'tables'}
                                    , cgp_id         => $cgp_id
                                    , date           => $self->date_to_upload
        );
        info( "Finished inserting CGP data" );

        return 0;
    }
    else {
        info( "$cluster_name CGP for " 
            . $self->date_to_upload 
            . ' already exists, skipping...' );
        return 1;
    }

}

no Moose;

__PACKAGE__->meta->make_immutable;