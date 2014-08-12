package CGPInsert::InsertDAO;

use 5.016;

use Moose;
use MooseX::Method::Signatures;

use Dancer ':syntax';

use Data::Dumper;
use DBI;

has 'database_path' => ( is => 'ro' );
has 'dbh'           => ( is => 'rw' );

method BUILD {
    my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $self->database_path, "", "" ) or die $!;

    $self->dbh( $dbh );

    info( 'DB connection made to ' . $self->database_path );
}

method insert_cgp_table( :$cluster_code, :$date ) {

    info("Inserting into CGP table");

    my $cgp_id       = $self->_get_max_cgp_id() + 1;

    my $sql = qq{ 
INSERT INTO cgp 
( cgp_id, cluster_code, cycle_end_month ) 
VALUES 
( '$cgp_id', '$cluster_code', '$date' );
};

info $sql;

    $self->dbh->do( $sql );

    return $cgp_id;
}

method insert_numbers ( :$table_name, :$table_headers, :$table_data, :$cgp_id ) {
    
    info( "Inserting data into $table_name" );

    my @columns = @{ $table_headers } ;
    my @values  = @{ $table_data };

    push @columns, 'cgp_id';
    push @values, $cgp_id;

    my $sql = "INSERT INTO $table_name ( " 
             . join ( ', ', @columns )
             . ' ) VALUES ( '
             . join ( ', ', @values )
             . ' )';

    debug( "Executing SQL: $sql" );

    $self->dbh->do( $sql );

}

method cgp_exists ( :$date, :$cluster_code ) {

    my $sql = qq{
SELECT cgp_id FROM cgp
WHERE  cycle_end_month = '$date'
AND    cluster_code    = '$cluster_code'
};

    return $self->_execute_sql_single( sql => $sql );

}

method _get_max_cgp_id() {
    
    my $sql = qq{
SELECT MAX(cgp_id) FROM cgp
};

    return $self->_execute_sql_single( sql => $sql ) || 0;

}

method get_cluster_code ( :$cluster_name, :$region ) {

    my $sql = qq{
SELECT c.cluster_code 
FROM   cluster  c
     , area     a
     , region   r 
WHERE  r.region_name  = '$region'
AND    r.region_name  = a.region_name
AND    c.area_number  = a.area_number
AND    c.cluster_name = '$cluster_name'
};

    return $self->_execute_sql_single( sql => $sql );

}

method _execute_sql_single ( :$sql ) {

    debug( "Executing SQL: $sql" );

    my $sth = $self->dbh->prepare( $sql );
    $sth->execute();

    my @return_value = $sth->fetchrow_array();
    $sth->finish();

    return $return_value[0]; 
}


no Moose;

__PACKAGE__->meta->make_immutable;