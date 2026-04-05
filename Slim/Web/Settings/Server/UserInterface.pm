package Slim::Web::Settings::Server::UserInterface;


# Logitech Media Server Copyright 2001-2024 Logitech.
# Lyrion Music Server Copyright 2024 Lyrion Community.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

use strict;
use base qw(Slim::Web::Settings);

use Slim::Player::Client;
use Slim::Display::Lib::Fonts;
use Slim::Display::Lib::TTFFonts;
use Slim::Utils::Log;
use Slim::Utils::Strings qw(string);
use Slim::Utils::Prefs;

my $prefs = preferences('server');
my $fontslog = logger('player.fonts');

sub name {
	return Slim::Web::HTTP::CSRF->protectName('INTERFACE_SETTINGS');
}

sub page {
	return Slim::Web::HTTP::CSRF->protectURI('settings/server/interface.html');
}

sub prefs {
	return ($prefs, qw(displaytexttimeout skin itemsPerPage refreshRate thumbSize additionalPlaylistButtons
					   longdateFormat shortdateFormat timeFormat showArtist showYear titleFormatWeb ttfText ttfFont));
}

sub handler {
	my ($class, $client, $paramRef, $pageSetup) = @_;

	# handle array prefs in this handler, scalar prefs in SUPER::handler
	my @prefs = qw(titleFormat);

	my $ttfPrefChanged   = 0;
	my $ttfFontChanged   = 0;
	my $clearTTFCache    = 0;

	if ($paramRef->{'saveSettings'}) {
		$clearTTFCache = $paramRef->{'clearTTFCache'} ? 1 : 0;

		$ttfPrefChanged = ($paramRef->{'pref_ttfText'} || 0) ne ($prefs->get('ttfText') || 0);
		my $oldTTFFont = $prefs->get('ttfFont') || '';
		my $newTTFFont = $paramRef->{'pref_ttfFont'} || '';
		my %availableTTFFonts = map { $_ => 1 } @{ Slim::Display::Lib::TTFFonts::availableTTFFonts() || [] };

		# Unknown value means "automatic" to preserve fallback behavior.
		if ($newTTFFont && !$availableTTFFonts{$newTTFFont}) {
			$newTTFFont = '';
			$paramRef->{'pref_ttfFont'} = '';
		}

		$ttfFontChanged = $newTTFFont ne $oldTTFFont;

		for my $pref (@prefs) {

			my @array;

			for (my $i = 0; defined $paramRef->{'pref_'.$pref.$i}; $i++) {

				push @array, $paramRef->{'pref_'.$pref.$i} if $paramRef->{'pref_'.$pref.$i};
			}

			$prefs->set($pref, \@array);
		}

		if ($paramRef->{'pref_titleFormatWeb'} ne $prefs->get('titleFormatWeb')) {

			for my $client (Slim::Player::Client::clients()) {

				$client->currentPlaylistChangeTime(Time::HiRes::time());
			}
		}


		if ($paramRef->{'pref_skin'} ne $prefs->get('skin')) {
			# use Classic instead of Default skin if the server's language is set to Hebrew
			if ($prefs->get('language') eq 'HE' && $paramRef->{'pref_skin'} eq 'Default') {

				$paramRef->{'pref_skin'} = 'Classic';

			}

			$paramRef->{'warning'} .= '<span id="popupWarning">' . string("SETUP_SKIN_OK") . '</span>';
		}

		for my $client (Slim::Player::Client::clients()) {

			$client->currentPlaylistChangeTime(Time::HiRes::time());
		}
	}

	for my $pref (@prefs) {
		$paramRef->{'prefs'}->{ 'pref_'.$pref } = [ @{ $prefs->get($pref) || [] }, '' ];
	}

	$paramRef->{'longdateoptions'}  = Slim::Utils::DateTime::longDateFormats();
	$paramRef->{'shortdateoptions'} = Slim::Utils::DateTime::shortDateFormats();
	$paramRef->{'timeoptions'}      = Slim::Utils::DateTime::timeFormats();

	$paramRef->{'skinoptions'} = { Slim::Web::HTTP::skins(1) };
	$paramRef->{'ttfFontOptions'} = [ map {
		my $label = $_;
		$label =~ s{.*[\\/]}{};
		{ value => $_, label => $label }
	} @{ Slim::Display::Lib::TTFFonts::availableTTFFonts() || [] } ];

	my $result = $class->SUPER::handler($client, $paramRef, $pageSetup);

	# Apply TrueType changes after prefs are saved.
	if ($ttfPrefChanged || $ttfFontChanged || $clearTTFCache) {
		my $fontCache = Slim::Display::Lib::Fonts::fontCacheFile();
		unlink $fontCache if $fontCache && -f $fontCache;
		Slim::Display::Lib::Fonts::loadFonts(1);

		if ($clearTTFCache) {
			Slim::Display::Lib::TTFFonts::forceRefreshTTFState();
		} else {
			Slim::Display::Lib::TTFFonts::refreshTTFFontSelection();
		}

		main::INFOLOG && $fontslog->info($clearTTFCache ? 'TrueType cache cleared' : 'TrueType settings changed');

		for my $client (Slim::Player::Client::clients()) {
			next unless $client && $client->display;
			eval { $client->display->resetDisplay(); $client->update() };
		}
	}

	return $result;
}

1;

__END__
