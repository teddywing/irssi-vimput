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


use constant VIMPUT_IPC_COMMAND_PREFIX => '%%%___VIMPUT___%%%: ';
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
	my ($fifo) = @_;

	if (!$ENV{TMUX}) {
		print 'no tmux'; # TODO: Replace with Irssi print
						 # MSGLEVEL_CLIENTERROR
		return;
	}

	my $random_unused_filename = tmpnam();

	# my $command = "vim ${\vimput_file}";
	my $command = "vim -c 'set buftype=acwrite' -c 'read ${\vimput_file}' -c '1 delete _' -c 'autocmd BufWriteCmd <buffer> :write $fifo | set nomodified' $random_unused_filename";
	system('tmux', 'split-window', $command);
}


sub update_input_line_when_finished {
	# my ($handle, $filename) = tempfile();
	# print $filename;
	# my $tempdir = tempdir('vimput-XXXXXXXXXX');
	# my $fifo_path = "$tempdir/fifo";
	# my $fifo;
	# $fifo->autoflush(1);

	# my $pid = fork();
	# die $! if not defined $pid;

# if ($pid == 0) { # child
	# my $fifo_path = tmpnam();
	# print 'F: ' . $fifo_path;
    #
	# mkfifo($fifo_path, 0600) or die $!;

	# my $tag;
	# my @args = ($fifo, \$tag);
	# $tag = Irssi::input_add(
	# 	fileno($fifo),
	# 	Irssi::INPUT_READ,
	# 	\&adljkhadhadfhjkl,
	# 	\@args
	# );

	# open $fifo, '<', $fifo_path or die $!;
	# open_tmux_split($fifo_path);
    #
	# $fifo->autoflush(1);
	# while (<$fifo>) {
	# 	# if ($_) {
	# 		# print 'hello';
	# 		print $_;
	# 	# }
	# }
	# close $fifo;

	# exit;
	# open $fifo, '<', $fifo_path or die $!;
	# my $x = 0;
	# while (<$fifo>) {
	# 	last if $x > 5;
	# 	print $_;
	# 	if ($_) {
	# 		print $_;
	# 		Irssi::gui_input_set($_);
    #
	# 		last;
	# 	}
	# 	sleep 2;
	# 	$x++;
	# }
	# close $fifo;
# }
# else {
# 	Irssi::pidwait_add($pid);
# }


	# open my $handle, "cat ${\vimput_file} |" or die $!;
	# while (<$handle>) {
	# 	print $_;
	# }
	# close $handle;


	# sub update_line {
	# 	open my $handle, '<', vimput_file or die $!;
	# 	while (<$handle>) {
	# 		Irssi::gui_input_set($_);
	# 	}
	# 	close $handle;
	# }
    #
	# my $tag = Irssi::timeout_add(1000, \&update_line);


	# my $fuckyoumotherfucker = '/tmp/fucking-fifo';
	# unlink $fuckyoumotherfucker;
	# open_tmux_split($fuckyoumotherfucker);
    #
	# mkfifo($fuckyoumotherfucker, 0600) or die $!;
	# open my $fifo, '<', $fuckyoumotherfucker, or die $!;
	# while (<$fifo>) {
	# 	print $_;
	# }
	# close $fifo;
	# unlink $fuckyoumotherfucker;


	my ($read_handle, $write_handle, $command_handle, $fuckface);

	pipe($read_handle, $write_handle);
	pipe($fuckface, $command_handle);
	# pipe($read_handle, $command_handle);

	# $write_handle->autoflush(1);
	# $write_handle->blocking(0);

	my $pid = fork();

	if (!defined $pid) {
		print "Failed to fork: $!";  # TODO: Irssi print
		close $read_handle;
		close $write_handle;
		close $command_handle;
		close $fuckface;
		return;
	}

if ($pid == 0) {
	# my $fuckyoumotherfucker = '/tmp/fucking-fifo';
	# unlink $fuckyoumotherfucker;
    #
	# # TODO: This needs to be done in the parent
	# open_tmux_split('/tmp/fucking-other-file', $fuckyoumotherfucker);
    #
	# mkfifo($fuckyoumotherfucker, 0600) or die $!;
	# open my $fifo, '<', $fuckyoumotherfucker, or die $!;
	# while (<$fifo>) {
	# 	chomp $_;
	# 	# Irssi::gui_input_set($_);
	# 	print $write_handle $_;
	# }
	# close $fifo;
	# unlink $fuckyoumotherfucker;

	my $fifo_path = tmpnam();
	# my $tempdir = tempdir('vimput.XXXXXXXXXX', TMPDIR => 1, CLEANUP => 1);
	# my $fifo_path = "$tempdir/fifo";

	# print $write_handle VIMPUT_IPC_COMMAND_PREFIX . $fifo_path;
	# print $command_handle $fifo_path;
	close $command_handle;

	open_tmux_split($fifo_path);

	mkfifo($fifo_path, 0600) or die $!;

	open my $fifo, '<', $fifo_path or die $!;
	$fifo->autoflush(1);

	while (<$fifo>) {
		print $write_handle $_;
	}

	close $fifo;

	# my $socket_path = $fifo_path;
    #
	# my $socket = IO::Socket::UNIX->new(
	# 	Local => $socket_path,
	# 	Type => SOCK_STREAM,
	# 	Listen => 1,
	# ) or die "Failed to create socket: $!";
    #
	# # $socket->blocking(0);
    #
	# my $connection = $socket->accept();
	# $connection->autoflush(1);
    #
	# while (my $line = <$connection>) {
	# 	print $write_handle $line;
	# }
    #
	# close $socket;

	close $write_handle;

	POSIX::_exit(0);
}
else {
	close $write_handle;
	close $command_handle;

	Irssi::pidwait_add($pid);

	my $pipe_tag;
	my @args = ($read_handle, \$pipe_tag);
	$pipe_tag = Irssi::input_add(
		fileno $read_handle,
		Irssi::INPUT_READ,
		\&pipe_input,
		\@args,
	);
	my $p2;
	my @ar2 = ($fuckface, \$p2);
	$p2 = Irssi::input_add(
		fileno $fuckface,
		Irssi::INPUT_READ,
		\&pipe_open_tmux_split,
		\@ar2,
	);
}
}


sub pipe_input {
	my ($args) = @_;
	my ($read_handle, $pipe_tag) = @$args;

	my $input = <$read_handle>;
	chomp $input;

	Irssi::gui_input_set($input);

	# TODO: Add $forked to not spawn more than one children unnecessarily

	close $read_handle;
	Irssi::input_remove($$pipe_tag);
}


sub pipe_open_tmux_split {
	my ($args) = @_;
	my ($read_handle, $pipe_tag) = @$args;

	my $fifo_path = <$read_handle>;

	# open_tmux_split('rando', $fifo_path);

	# TODO: Add $forked to not spawn more than one children unnecessarily

	close $read_handle;
	Irssi::input_remove($$pipe_tag);
}


# TODO: Find out if it's possible to do this is a command
Irssi::signal_add_last 'gui key pressed' => sub {
	my ($key) = @_;

	if ($key eq CTRL_X) {
		write_input(Irssi::parse_special('$L', undef, 0));
		# open_tmux_split();
		update_input_line_when_finished();
	}
};
