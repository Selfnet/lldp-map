package Walker;

use 5.010;
use strict;
use warnings;
use Net::SNMP;

my $lldpRemSysName = '.1.0.8802.1.1.2.1.4.1.1.9';
my $dontWalk = '\.server\.selfnet\.de$';
my $dontShow = '^\(none\)\.\(none\)$';

sub new {
    my $class = shift;
    my $self = {
        nodes => {},
        edges => [],
    };
    bless($self, $class);
    return $self;
}

sub walk {
    my ($self, $node_name) = @_;
    say "Walking $node_name...";
    my $node = $self->{nodes}->{$node_name};
    if (!$node) {
        $node = {};
        $self->{nodes}->{$node_name} = $node;
    }
    my @neighbors = grep(!/$dontShow/, get_neighbors($node_name));
    $node->{neighbors} = @neighbors;
    for my $neighbor_name (@neighbors) {
        my $neighbor = $self->{nodes}->{$neighbor_name};
        if (!$neighbor || !$neighbor->{neighbors}) {
            push $self->{edges}, [$node_name, $neighbor_name];
        }
    }
    for my $neighbor_name (@neighbors) {
        if (!$self->{nodes}->{$neighbor_name} && $neighbor_name !~ /$dontWalk/) {
            $self->walk($neighbor_name);
        }
    }
}

sub get_neighbors {
    my ($host) = @_;
    my ($session, $error) = Net::SNMP->session(
        -hostname => $host,
        -version => '2',
        #-domain => 'udp6',
        -maxMsgSize => 65535,
    );
    if (!$session) {
        say "ERROR: $error";
        return;
    }

    my $result = $session->get_entries(
        -columns => [$lldpRemSysName],
    );
    if (!$result) {
        say 'ERROR: ', $session->error();
        return;
    }

    return map(lc, values $result);
}

sub save {
    my $self = shift;
    my $path = shift;
    say "Saving...";
    
    open(my $output, '>', $path);
    say $output 'graph {';
    for my $edge (@{$self->{edges}}) {
        my ($n1, $n2) = @{$edge};
        say $output "    \"$n1\" -- \"$n2\";";
    }
    say $output '}';
}

1;
