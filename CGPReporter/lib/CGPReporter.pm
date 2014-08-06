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
};

true;
