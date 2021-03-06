# vimput.pl
#
# Opens the current input line in a new Tmux split in Vim. When the Vim
# buffer is written, Irssi's prompt will be updated from the contents of the
# buffer.
#
# **Note:** In order to use this script, you'll have to make a key binding to
# Vimput. For example, to bind Ctrl-X:
#
#     /BIND ^X command script exec Irssi::Script::vimput::vimput
#
#
# Copyright (c) 2017 Teddy Wing
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;

use File::Temp qw(tmpnam);
use POSIX qw(mkfifo);

use Irssi;

our $VERSION = '1.01';
our %IRSSI = {
	authors     => 'Teddy Wing',
	contact     => 'irssi@teddywing.com',
	name        => 'Vimput',
	description => 'Edit Irssi messages in Vim.',
	license     => 'GPL',
};


use constant ERROR_PREFIX => 'ERROR: ';
use constant OK_PREFIX => 'OK: ';

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
	my ($fifo, $error_handle, $cursor_position) = @_;

	if (!$ENV{TMUX}) {
		print $error_handle ERROR_PREFIX . 'Not running in tmux.';

		return 0;
	}

	my $random_unused_filename = tmpnam();

	my $command = "vim -c 'set buftype=acwrite' -c 'read ${\vimput_file}' -c '1 delete _' -c 'normal! ${cursor_position}l' -c 'autocmd BufWriteCmd <buffer> :write $fifo | set nomodified' $random_unused_filename";
	system('tmux', 'split-window', $command);

	return 1;
}


# Forks a child process and opens a pipe for the child to communicate with
# the parent. In the child process, open a Tmux split, create a FIFO pipe,
# and send the contents of the FIFO to the parent.
sub open_tmux_and_update_input_line_when_finished {
	return if $forked;

	my ($cursor_position) = @_;

	my ($read_handle, $write_handle);

	pipe($read_handle, $write_handle);

	sub cleanup {
		close $read_handle;
		close $write_handle;
	}

	my $pid = fork();

	if (!defined $pid) {
		Irssi::print("Failed to fork: $!", MSGLEVEL_CLIENTERROR);

		cleanup();

		return;
	}

	$forked = 1;

	if (is_child_fork($pid)) {
		my $fifo_path = tmpnam();

		open_tmux_split($fifo_path, $write_handle, $cursor_position) or do {
			cleanup();
			POSIX::_exit(1);
		};

		# The input line will be sent from Vim on this FIFO.
		mkfifo($fifo_path, 0600) or do {
			print $write_handle ERROR_PREFIX . "Failed to make FIFO: $!";

			cleanup();

			POSIX::_exit(1);
		};

		open my $fifo, '<', $fifo_path or do {
			print $write_handle ERROR_PREFIX . "Failed to open FIFO: $!";

			cleanup();

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


# Read messages in the parent process from the child over a pipe. Print error
# messages to the Irssi window. An OK message will be used to replace the
# current input line.
sub pipe_input {
	my ($args) = @_;
	my ($read_handle, $pipe_tag) = @$args;

	my $input = <$read_handle>;

	if (is_error_message($input)) {
		$input = substr($input, length(ERROR_PREFIX));

		Irssi::print($input, MSGLEVEL_CLIENTERROR);
	}
	elsif (is_ok_message($input)) {
		$input = substr($input, length(OK_PREFIX));
		chomp $input;

		Irssi::gui_input_set($input);
	}

	$forked = 0;

	close $read_handle;
	Irssi::input_remove($$pipe_tag);
}


# Test whether `$pid` is a child process.
sub is_child_fork {
	my ($pid) = @_;

	return $pid == 0;
}


# Test whether `$string` starts with `ERROR_PREFIX`.
sub is_error_message {
	my ($string) = @_;

	return index($string, ERROR_PREFIX) == 0;
}


# Test whether `$string` starts with `OK_PREFIX`.
sub is_ok_message {
	my ($string) = @_;

	return index($string, OK_PREFIX) == 0;
}


# Since we don't provide a command, we have to do some tricks to print help
# output. /HELP won't list us in its output, but you can still use
# `/help vimput`. While a `command_bind` to 'help' would work, it doesn't give
# us completion for 'vimput'. Here, we hack the subcommand functionality to put
# us in the completion list for `/help`.
Irssi::command_bind('help vimput', sub {
	my $help = <<HELP;
%9Details:%9

    Opens the current input line in a new Tmux split in Vim. When the Vim
    buffer is written, Irssi's prompt will be updated from the contents of the
    buffer.

    %9Note:%9 In order to use this script, you'll have to make a key binding to
    Vimput. For example, to bind Ctrl-X:

        /BIND ^X command script exec Irssi::Script::vimput::vimput
HELP

	Irssi::print($help, MSGLEVEL_CLIENTCRAP);
});

Irssi::command_bind('help', sub {
	my ($data, $server, $item) = @_;

	if ($data !~ /^vimput\s*$/) {
		return;
	}

	Irssi::command_runsub('help', $data, $server, $item);
	Irssi::signal_stop();
});


# Main entrypoint.
sub vimput {
	my $cursor_position = Irssi::gui_input_get_pos();

	write_input(Irssi::parse_special('$L', undef, 0));
	open_tmux_and_update_input_line_when_finished($cursor_position);
}
