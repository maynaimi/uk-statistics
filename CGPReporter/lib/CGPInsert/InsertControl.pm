package CGPInsert::InsertControl;

use 5.016;

use Moose;
use MooseX::Method::Signatures;
use Data::Dumper;

use CGPInsert::InsertDAO;

has 'logger'        => ( is => 'ro' );
has 'database_path' => ( is => 'ro' );
has 'db_access'     => ( is => 'rw' );

method BUILD {
    $self->db_access( 
        new CGPInsert::InsertDAO( database_path => $self->database_path
                                , logger        => $self->logger ) 
    );
}

method check_cluster_details ( :$cluster_details ) {

    $self->logger->info( "Checking cluster details" );

    my $cluster_data     = $cluster_details->{'data'};
    my $regional_council = $cluster_data->{'regional'};
    my $cluster_name     = $cluster_data->{'cluster'};
    my $region           = $self->get_region( $regional_council );
    my $cluster_code;
    ( $cluster_name, $cluster_code )
                         = $self->get_cluster_code( $cluster_name, $region );    
    
    $cluster_data->{ 'cluster'      } = $cluster_name;
    $cluster_data->{ 'region'       } = $region;
    $cluster_data->{ 'cluster_code' } = $cluster_code;

    $cluster_details->{'data'} = $cluster_data;

    return $cluster_details;

}

method insert_cgp ( :$cluster_code, :$date, :$region ) {

    $self->logger->info( "Inserting new CGP" );

    my $cgp_id;

    my $cgp_exists = $self->db_access->cgp_exists( cluster_code => $cluster_code
                                                 , date         => $date
    );

    if ( ! $cgp_exists ) {
        $cgp_id = $self->db_access->insert_cgp_table( cluster_code => $cluster_code
                                                    , date         => $date 
        );
    }

    return $cgp_id;
}

method insert_cgp_data ( :$all_table_data, :$cgp_id, :$date ) {

    foreach my $table_number ( keys %{ $all_table_data } ) {
    
        my $table_details = $all_table_data->{ $table_number };
        my $table_name    = $table_details->{ 'name'    };
        my $table_data    = $table_details->{ 'data'    };
        my $table_headers = $table_details->{ 'headers' };
    
        $self->logger->info( "Insert data into $table_name for $date" );
    
        $self->db_access->insert_numbers( table_name    => $table_name
                                        , table_headers => $table_headers
                                        , table_data    => $table_data->{ $date }
                                        , cgp_id        => $cgp_id
        );
    }
}

method get_region( $regional_council ) {
    
    if ( $regional_council =~ m/^\s*\w+\s*$/ ) {
        return $regional_council;
    }

    $regional_council =~ m/for (\w+)/;

    if ( $1 ) {
        return $1;
    }
    else {
        $self->logger->error( "Could not find region in : $regional_council" );
    }

}

method get_cluster_code ( $cluster, $region ) {
 
    $cluster =~ m/(\w+)\s*\((\d+)\)/;

    my $cluster_code;

    if ( $1 && $2 ) {
        $cluster      = $1;
        $cluster_code = $2;
    }
    else {
        $cluster_code 
            = $self->db_access->get_cluster_code( cluster_name => $cluster
                                                , region       => $region       );
        
        if ( ! $cluster_code ) {
            $self->logger->error( "Could not find cluster_code for $cluster : $region" );
            exit 1;
        }
    }

    return ( $cluster, $cluster_code );
}

no Moose;

__PACKAGE__->meta->make_immutable;