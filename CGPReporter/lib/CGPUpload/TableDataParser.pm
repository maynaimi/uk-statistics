package CGPParser::TableDataParser;

use Moose;
use MooseX::Method::Signatures;

use Data::Dumper;
use DBI;
use Carp;

has 'logger'     => ( is => 'ro' );
has 'table_text' => ( is => 'ro' );
has 'cgp_hash'   => ( is => 'ro' );


method BUILD {
    
    $self->logger->debug( "Adding text from word doc to data hash..." );

    # Add text from word doc to cgp hash for cgp details
    #
    $self->cgp_hash->{'cluster_details'}->{'text'} = @{ $self->table_text }[0];
    # Add text from word doc to table hash for table details
    #
    my $table_hash = $self->cgp_hash->{'tables'};

    foreach my $key ( keys %{ $table_hash } ) {
        $self->cgp_hash->{'tables'}->{ $key }->{'text'} = @{ $self->table_text }[$key];
    }

}

method get_cluster_details () {

    $self->logger->debug( "Extracting metadata..." );

    my $cluster_details_hash = $self->cgp_hash->{'cluster_details'};
    my @search_terms         = keys %{ $cluster_details_hash->{'cgp_table_map'} };
    my $cluster_details_text = $cluster_details_hash->{'text'};

    my $data_hash;

    foreach my $element ( @search_terms ) {

        my $value = $self->_get_value( data   => $cluster_details_text
                                     , lookup => $element );

        $data_hash->{ $element } = $value;
    }

    return $data_hash;
    
}

method get_table_data ( :$table_number ) {

    my $table_reference = $self->cgp_hash->{ 'tables' }->{ $table_number };

    $self->logger->debug( "Removing headers from table data for table $table_number" );

    $self->cgp_hash->{'tables'}->{ $table_number }->{'text'} 
        = $self->_get_text_without_headers( table_hash => $table_reference );

    $self->logger->debug( "Structuring data for table $table_number" );

    my $structured_data = $self->_structure_data( table_hash   => $table_reference
                                                , table_number => $table_number 
    );

    return $structured_data;

}

method _structure_data( :$table_hash, :$table_number ) {

    my $table_text      = $table_hash->{ 'text' };
    my $date_col_count  = $table_hash->{ 'table_details' }->{ 'date_col_count'  };
    my $total_col_count = $table_hash->{ 'table_details' }->{ 'total_col_count' };

    my @elements = split ( "\n", $table_text );

    my $structured_data;

    if ( ( @elements % $total_col_count ) != 0 ) {
        $self->logger->error( "Incorrect number of elements in Table $table_number" );
        exit 1;
    }

    my $row_count = @elements / $total_col_count;

    $self->logger->info( "Reading $row_count row(s) for table $table_number..." );

    for ( my $i = 0; $i < $row_count; $i++ ) {

        my $row_multiplier = $i * $total_col_count;

        my ( @date_array, @data_array, $date_count, $data_count ); 
 
        for $date_count ( 0 .. $date_col_count-1 ) {
            push @date_array, $elements[ $row_multiplier + $date_count ];
        }

        for $data_count ( 0 .. $total_col_count-$date_col_count-1 ) {
            push @data_array, $elements[ $row_multiplier + $date_col_count + $data_count ];
        }

        my $date = $self->_format_date( date_ref => \@date_array );

        $structured_data->{ $date } = \@data_array;
    }

    return $structured_data;

}

method _format_date( :$date_ref ) {

    # TODO: This needs thinking about
    #
    my @date_array = @{ $date_ref };

    my $date;

    if ( @date_array > 1 ) {
        $date = $date_array[-1];
        $date =~ m/(\d+-)?(\w+-\d+)/;

        $date = $2 if ( $2 );
    }
    else {
        $date = $date_array[0];
    }

    return $date;
}

method _get_text_without_headers( :$table_hash ) {

    my $table_text   = $table_hash->{ 'text' };
    my $header_count = $table_hash->{ 'table_details' }->{ 'header_row_count' };

    $table_text =~ s/(.*\n){$header_count}//;

    return $table_text;

}

method _get_value( :$data, :$lookup ) {

    my $value;

    $data =~ m/\w*$lookup[^:]*:\s*([\w\s,()']*)\s*\n/i;

    if ( $1 ) {
        $value = $1;
        $value =~ s/\s*$//;
        $self->logger->debug( "Returning *$value* for $lookup" );
    }
    else {
        $value = '';
        $self->logger->warn( "Value for $lookup not found" );
    }

    return $value;

}


no Moose;

__PACKAGE__->meta->make_immutable;