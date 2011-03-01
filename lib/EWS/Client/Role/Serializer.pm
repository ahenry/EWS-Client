use strict;

# this is a little role/trait that allows attributes to indicate that they
# wish to be serialized by the main role down at the bottom
package EWS::Client::Role::Trait::Serialized;
BEGIN {
  $EWS::Client::Role::Trait::Serialized::VERSION = '1.103620';
}
use Moose::Role;

has serialization_helper => (
    is => 'rw',
    isa => 'CodeRef',
    predicate => 'has_serialization_helper',
);

# if the attribute is an Arrayref[] type, it needs to have a singular_name
has singular_name => (
    is => 'rw',
    isa => 'Str'
);

no Moose::Role;

# Note: see http://docs.activestate.com/activeperl/5.12/lib/Moose/Cookbook/Meta/Recipe3.html
package Moose::Meta::Attribute::Custom::Trait::Serialized;
sub register_implementation {'EWS::Client::Role::Trait::Serialized'}

# here's the main role, which adds a method which will serialize the object in
# a manner suitable for inclusion in an Items stanza to be processed in
# XML::Compile, and sent in an EWS web request
package EWS::Client::Role::Serializer;
BEGIN {
  $EWS::Client::Role::Serializer::VERSION = '1.103620';
}

use Moose::Role;

has SerializationItemName => (
    is => 'ro',
    isa => 'Str',
    default => 'Item',
);

sub serialize {
    my ($self) = @_;

    my $result;
    my @attributes = grep { $_->does('EWS::Client::Role::Trait::Serialized') }
                          $self->meta->get_all_attributes();

    # perform serialization on all of the attributes which have indicated that
    # they wish to be serialized (via a "Serialized" entry in their traits)
    foreach my $attribute (@attributes) {
        next unless $attribute->has_value($self);

        my $reader = $attribute->get_read_method;
        my $value = $self->$reader;

        unless ($attribute->has_serialization_helper) {
            # default case is to just use the attribute name and value
            if (ref $value eq 'ARRAY') {
                my $arraykey = "cho_" . $attribute->singular_name;
                $result->{$attribute->name} = { $arraykey => [ ] };
                my $array = $result->{$attribute->name}->{$arraykey};

                foreach my $item (@$value) {
                    push(@$array, { $attribute->singular_name => $item });
                }
            } else {
                $result->{$attribute->name} = $value;
            }
        } else {
            # otherwise call the serialization helper function provided
            $result->{$attribute->name} = 
                $attribute->serialization_helper->($self, $value);
        }
    }

    # finally, wrap the item in it's little hashref that tells EWS what type
    # of item it is.  This will be placed in an array of cho_BlahBlah
    return { $self->SerializationItemName => $result };
}

no Moose::Role;

1;