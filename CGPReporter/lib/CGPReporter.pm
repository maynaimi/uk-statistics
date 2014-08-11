package CGPReporter;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/upload' => sub {
    template 'upload';
};

get '/select_date' => sub {
	template 'select_date';
	# my @dates = ('Apr-2013', 'Jul-2013');
    # template 'select_date', \@dates;
};

true;
