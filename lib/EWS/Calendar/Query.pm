package EWS::Calendar::Query;
use Moose;

use DateTime;

has start => (
    is => 'ro',
    isa => 'DateTime',
    required => 1,
);

has end => (
    is => 'ro',
    isa => 'DateTime',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

