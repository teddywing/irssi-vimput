use strict;

use Irssi;

our $VERSION = '1.00';
our %IRSSI = {
	authors     => 'Teddy Wing',
	contact     => 'irssi@teddywing.com',
	name        => 'Vimput',
	description => '',
	license     => 'GPL',
};


Irssi::signal_add_last 'gui key pressed' => sub {
	my ($key) = @_;

	print Irssi::parse_special('$L', undef, 0);
};
