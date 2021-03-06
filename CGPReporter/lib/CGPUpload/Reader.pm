package CGPUpload::Reader;

use Moose;
use MooseX::Method::Signatures;

use Dancer ':syntax';

use Data::Dumper;
use DBI;
use Carp;

use Win32::OLE;
use utf8;

has 'file_name' => ( is => 'ro' );
has 'word_doc'  => ( is => 'rw' );
has 'tables'    => ( is => 'rw' );

method open_word_doc() {
    
    Win32::OLE->Option( Warn => 3 );

    my $word = Win32::OLE->new( 'Word.Application' ) or die "Couldn't run Word";

    if ( ! $word->Documents ) {
        error "word->Documents is unavailable.";
        exit 1;
    }

    my $doc = $word->Documents->Open( 
                        { FileName => $self->file_name,
                        , ReadOnly => 1 }
    ) or die "Cannot open file: ". $self->file_name;

    $self->word_doc( $doc );

    info 'Word document opened.';
}

method get_cgp_tables() {

    my ( $object, $enum, $table );
    my @tables = ();

    my $Doc = $self->word_doc;

    $enum = Win32::OLE::Enum->new( $Doc->Tables ) 
                or croak "Cannot enumerate through Word tables.";

    while ( ( $object = $enum->Next ) ) {

        $table = $object->Range->{Text};

        if ( length( $table ) < 2 ) {
            next;
        }

        debug 'Removing special characters from text';

        $table =~ s/[\n|\r]/ /g;
        $table =~ s/\a/\n/g;
        $table =~ s/\cK/-/g;
        $table =~ s/Bahá.í/Baha'i/ig;
        $table =~ s/\s*\n/\n/g;
        
        push( @tables, $table );
    }

    $self->tables( \@tables );

    return \@tables;
}

method write_to_txt_file ( :$file_data_text ) {

    open my $FILELOG, ">$file_data_text" or croak "Cannot open log file: $file_data_text";
   
    foreach my $table ( @{ $self->tables } ){
        print $FILELOG $table, "\n";
    }

    close $FILELOG;
    info $self->file_name . " has been textlized to file $file_data_text";

}


no Moose;

__PACKAGE__->meta->make_immutable;