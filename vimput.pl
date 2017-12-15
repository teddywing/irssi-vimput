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


# The location of the temporary file where prompt contents are written.
sub tempfile {
	Irssi::get_irssi_dir() . '/VIMPUT_MSG';
}


# Write the given string to our tempfile.
sub write_input {
	my ($message) = @_;

	open my $handle, '>', tempfile or die $!;
	print $handle $message;
	close $handle;
}


Irssi::signal_add_last 'gui key pressed' => sub {
	my ($key) = @_;

	write_input(Irssi::parse_special('$L', undef, 0));
};
