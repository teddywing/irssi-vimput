use strict;

use File::Temp qw(tempfile);

use Irssi;

our $VERSION = '1.00';
our %IRSSI = {
	authors     => 'Teddy Wing',
	contact     => 'irssi@teddywing.com',
	name        => 'Vimput',
	description => '',
	license     => 'GPL',
};


use constant CTRL_X => 24;


# The location of the temporary file where prompt contents are written.
sub vimput_file {
	Irssi::get_irssi_dir() . '/VIMPUT_MSG';
}


# Write the given string to our vimput_file.
sub write_input {
	my ($message) = @_;

	open my $handle, '>', vimput_file or die $!;
	print $handle $message;
	close $handle;
}


# Open a Tmux split containing a Vim instance editing the vimput_file.
sub open_tmux_split {
	if (!$ENV{TMUX}) {
		print 'no tmux'; # TODO: Replace with Irssi print
						 # MSGLEVEL_CLIENTERROR
		return;
	}

	my $command = "vim ${\vimput_file}";
	system('tmux', 'split-window', $command);
}


sub update_input_line_when_finished {
	my ($handle, $filename) = tempfile();
	print $filename;

	open $handle, '<', $filename or die $!;
	# my $x = 0;
	while (<$handle>) {
		print $_;
		if ($_) {
			print $_;
			Irssi::gui_input_set($_);

			close $handle;
			last;
		}
		# print $_;
		# sleep 2;
		# $x++;
	}
}


# TODO: Find out if it's possible to do this is a command
Irssi::signal_add_last 'gui key pressed' => sub {
	my ($key) = @_;

	if ($key eq CTRL_X) {
		write_input(Irssi::parse_special('$L', undef, 0));
		open_tmux_split();
		update_input_line_when_finished();
	}
};
