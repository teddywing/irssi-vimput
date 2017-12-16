use strict;

use File::Temp qw(tmpnam tempfile);
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
	my ($filename, $fifo) = @_;

	if (!$ENV{TMUX}) {
		print 'no tmux'; # TODO: Replace with Irssi print
						 # MSGLEVEL_CLIENTERROR
		return;
	}

	# my $command = "vim ${\vimput_file}";
	my $command = "vim -c 'set buftype=acwrite' -c 'read ${\vimput_file}' -c '1 delete _' -c 'autocmd BufWriteCmd <buffer> :write $fifo | set nomodified' $filename";
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


	my ($read_handle, $write_handle);

	pipe($read_handle, $write_handle);

	my $pid = fork();

	if (!defined $pid) {
		print "Failed to fork: $!";  # TODO: Irssi print
		close $read_handle;
		close $write_handle;
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

	print $write_handle 'worked?';
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
	print 'I: ' . $input;
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
