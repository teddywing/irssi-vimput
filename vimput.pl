use strict;

use File::Temp qw(tmpnam tempfile tempdir);
use IO::Socket::UNIX;
use POSIX qw(mkfifo);

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
use constant ERROR_PREFIX => 'ERROR: ';
use constant OK_PREFIX => 'OK: ';

my $child;
my $forked = 0;


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
	my ($fifo, $error_handle) = @_;
	# my ($fifo) = @_;

	if (!$ENV{TMUX}) {
		# Irssi::print('Not running in tmux.', MSGLEVEL_CLIENTERROR);
		print $error_handle ERROR_PREFIX . 'Not running in tmux.';

		return 0;
	}

	my $random_unused_filename = tmpnam();

	my $command = "vim -c 'set buftype=acwrite' -c 'read ${\vimput_file}' -c '1 delete _' -c 'autocmd BufWriteCmd <buffer> :write $fifo | set nomodified' $random_unused_filename";
	system('tmux', 'split-window', $command);

	return 1;
}


sub update_input_line_when_finished {
	return if $forked;

	my ($read_handle, $write_handle);

	pipe($read_handle, $write_handle);

	sub cleanup {
		close $read_handle;
		close $write_handle;
	}

	my $pid = fork();
	$child = $pid;

	if (!defined $pid) {
		Irssi::print("Failed to fork: $!", MSGLEVEL_CLIENTERROR);

		cleanup();

		return;
	}

	$forked = 1;

	if (is_child_fork($pid)) {
		my $fifo_path = tmpnam();

		open_tmux_split($fifo_path, $write_handle) or do {
			cleanup();
			POSIX::_exit(1);
		};

		mkfifo($fifo_path, 0600) or do {
			cleanup();
			# die $!;
			POSIX::_exit(1);
		};

		open my $fifo, '<', $fifo_path or do {
			cleanup();
			# die $!;
			POSIX::_exit(1);
		};
		$fifo->autoflush(1);

		while (<$fifo>) {
			print $write_handle OK_PREFIX . $_;
		}

		close $fifo;

		close $write_handle;

		POSIX::_exit(0);
	}
	else {
		close $write_handle;

		Irssi::pidwait_add($pid);

		my $pipe_tag;
		my @args = ($read_handle, \$pipe_tag);
		$pipe_tag = Irssi::input_add(
			fileno $read_handle,
			Irssi::INPUT_READ,
			\&pipe_input,
			\@args,
		);
	}
}


sub pipe_input {
	my ($args) = @_;
	my ($read_handle, $pipe_tag) = @$args;

	my $input = <$read_handle>;

	if (index($input, ERROR_PREFIX) == 0) {
		$input = substr($input, length(ERROR_PREFIX));

		Irssi::print($input, MSGLEVEL_CLIENTERROR);
	}
	elsif (index($input, OK_PREFIX) == 0) {
		$input = substr($input, length(OK_PREFIX));
		chomp $input;

		Irssi::gui_input_set($input);
	}

	$forked = 0;

	close $read_handle;
	Irssi::input_remove($$pipe_tag);
}


sub is_child_fork {
	my ($pid) = @_;

	return $pid == 0;
}


# TODO: Find out if it's possible to do this is a command
Irssi::signal_add_last 'gui key pressed' => sub {
	my ($key) = @_;

	if ($key eq CTRL_X) {
		write_input(Irssi::parse_special('$L', undef, 0));
		update_input_line_when_finished();
	}
};
