package DatabaseCreator;

use 5.016;

use Moose;
use MooseX::Method::Signatures;

use DBI;

has 'db_file'          => ( is => 'ro' );
has 'logger'           => ( is => 'ro' );
has 'dbh'              => ( is => 'rw' );

method BUILD {

    $self->logger->info( 'Connecting to ' . $self->db_file );
    
    my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $self->db_file, "", "" ) or die $!;

    $self->dbh( $dbh );

}

method DESTROY {
    $self->logger->debug( "Disconnecting from database" );
    $self->dbh->disconnect();  
}

method create_objects ( :$directory ) {

    my @files = <$directory/*>;

    $self->logger->info( "Creating tables in $directory" );
    
    foreach my $file ( @files ) {

        say "---------------------------------";
        say "Opening $file...";
        
        open( my $FILE, "<", $file );
        
        my $table_sql = '';
        
        while ( <$FILE> ) { 
            $table_sql .= $_;
        }

        say $table_sql;
        
        $self->dbh->do( $table_sql );
    }
}

method insert_initial_data() {

    my $sql = "INSERT INTO region (region_name) VALUES ('England')";
    $self->dbh->do( $sql );

    $sql = "INSERT INTO cluster (cluster_code, cluster_name) VALUES ('EC18', 'Essex')";
    $self->dbh->do( $sql );

}

no Moose;

__PACKAGE__->meta->make_immutable;