package Slim::Display::Lib::TTFFonts;

# Lyrion Music Server Copyright 2026 Lyrion Community.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

=head1 NAME

Slim::Display::Lib::TTFFonts

=head1 DESCRIPTION

TrueType font rendering support for Lyrion Music Server graphics displays.

Handles:

=over 4

=item * TTF font discovery across Graphics directories and plugins

=item * Parsing of per-font ttfmetrics.conf configuration files

=item * Rasterization of individual characters via Font::FreeType

=back

Configuration is loaded from C<ttfmetrics.conf> files found in any Graphics
directory (core or plugin). See C<display-font-prefs.md> section 8 for the
format documentation.

=cut

use strict;

use File::Slurp qw(read_file);
use File::Basename;
use File::Spec::Functions qw(catdir);
use Path::Class;
use Tie::Cache::LRU;

use Slim::Utils::Log;
use Slim::Utils::Prefs;

use constant FT_RENDER_MODE_MONO => 2;

my $prefs = preferences('server');
my $log   = logger('player.fonts');

# Developer switches for testing/debugging behavior.
my $reloadTTFMetricsOnFontChange = 0;
my $useTTFGlyphCache             = 1;

sub setReloadTTFMetricsOnFontChange {
	$reloadTTFMetricsOnFontChange = $_[0] ? 1 : 0;
}

sub setUseTTFGlyphCache {
	$useTTFGlyphCache = $_[0] ? 1 : 0;
}

# ---------------------------------------------------------------------------
# FreeType availability check (lazy, cached)
# ---------------------------------------------------------------------------

my $hasFreeType;
my $canUseFreeType_fn = sub {
	return $hasFreeType if defined $hasFreeType;
	main::DEBUGLOG && $log->debug('Loading Font::FreeType');
	eval { require Font::FreeType };
	if ($@) {
		Slim::Utils::Log::logWarning("Unable to load TrueType font support: $@");
	}
	$hasFreeType = $@ ? 0 : 1;
	return $hasFreeType;
};

# ---------------------------------------------------------------------------
# Active TTF state
# ---------------------------------------------------------------------------

my ($ft, $TTFFontFile);
my $lastLoggedTTFRenderKey;
my $lastLoggedTTFMetricsKey;

# Keep a cache of up to 256 rendered TTF characters at a time.
tie my %TTFCache, 'Tie::Cache::LRU', 256;
%TTFCache = ();

# ---------------------------------------------------------------------------
# Metrics config state
# ---------------------------------------------------------------------------

my $loadedTTFMetrics;

my %ttfMetricsByFile;   # TTF basename -> bmp-font -> { FTFontSize, FTBaseline }
my %ttfUCByFile;        # TTF basename -> bmp-font -> 1
my %ttfNoUCByFile;      # TTF basename -> bmp-font -> 1
my %ttfAliasesByFile;   # TTF basename -> new-bmp  -> existing-bmp
my %ttfSectionAlias;    # TTF basename -> other TTF basename

sub _clearTTFMetrics {
	$loadedTTFMetrics = undef;
	%ttfMetricsByFile = ();
	%ttfUCByFile = ();
	%ttfNoUCByFile = ();
	%ttfAliasesByFile = ();
	%ttfSectionAlias = ();
	$lastLoggedTTFMetricsKey = undef;
}

sub _resetTTFState {
	$ft = undef;
	$lastLoggedTTFRenderKey = undef;
	%TTFCache = ();
}

# Extract basename from the active TTF path and resolve section aliases.
sub _ttfBaseName {
	return unless defined $TTFFontFile;
	(my $b = $TTFFontFile) =~ s{.*[\\/]}{};
	return _resolveTTFSection($b);
}

sub _logTTFMetricsSelection {
	my ($bmpFont, $ttfBase, $source, $entry) = @_;
	return unless main::INFOLOG;

	my $size     = $entry ? $entry->{FTFontSize} : '-';
	my $baseline = $entry ? $entry->{FTBaseline} : '-';
	my $key      = join('|', $TTFFontFile // '', $ttfBase // '', $bmpFont // '', $source // '', $size, $baseline);

	return if defined $lastLoggedTTFMetricsKey && $lastLoggedTTFMetricsKey eq $key;
	$lastLoggedTTFMetricsKey = $key;

	$log->info("TTF metrics: bmp=$bmpFont source=$source size=$size baseline=$baseline");
}

# ---------------------------------------------------------------------------
# Priority order for TTF font discovery (checked before alphabetical scan)
# ---------------------------------------------------------------------------

my @ttfFontCandidates = qw(
	arialuni.ttf
	ARIALUNI.TTF
	CODE2000.TTF
	Cyberbit.ttf
	CYBERBIT.TTF
);

# ---------------------------------------------------------------------------
# Public: utilities
# ---------------------------------------------------------------------------

sub graphicsDirs {
	# Font files are allowed in the core Graphics dir and plugin Graphics dirs.
	return (
		Slim::Utils::OSDetect::dirsFor('Graphics'),
		Slim::Utils::PluginManager->dirsFor('Graphics'),
	);
}

sub canUseFreeType {
	return $canUseFreeType_fn->();
}

sub currentTTFFile {
	return $TTFFontFile;
}

# ---------------------------------------------------------------------------
# Public: font selection
# ---------------------------------------------------------------------------

sub availableTTFFonts {
	my %seen;
	my @priorityFound;
	my @found;

	# Legacy priority-ordered candidates come first.
	for my $dir (graphicsDirs()) {
		for my $name (@ttfFontCandidates) {
			my $file = catdir($dir, $name);
			next unless -e $file;
			next if $seen{$file}++;
			push @priorityFound, $file;
		}
	}

	# Then all other .ttf files, sorted alphabetically.
	for my $dir (graphicsDirs()) {
		next unless -d $dir;
		my $d = dir($dir);
		while (my $obj = $d->next) {
			my $file = $obj->stringify;
			next unless $file =~ /\.ttf$/i;
			next if $seen{$file}++;
			push @found, $file;
		}
	}

	return [ @priorityFound, sort @found ];
}

sub selectedTTFFontFile {
	my $pref      = $prefs->get('ttfFont') || '';
	my $available = availableTTFFonts();

	if ($pref) {
		for my $f (@$available) {
			return $f if $f eq $pref;
		}
	}

	return @$available ? $available->[0] : undef;
}

sub refreshTTFFontSelection {
	my $selected = selectedTTFFontFile();

	if (($selected // '') ne ($TTFFontFile // '')) {
		$TTFFontFile = $selected;
		_resetTTFState();
		_clearTTFMetrics() if $reloadTTFMetricsOnFontChange;
	}

	return $TTFFontFile;
}

# Force-refresh all in-memory TTF state, including metrics, even if selected
# font does not change. Useful for explicit cache reset actions in settings UI.
sub forceRefreshTTFState {
	$TTFFontFile = selectedTTFFontFile();
	_resetTTFState();
	_clearTTFMetrics();

	return $TTFFontFile;
}

# ---------------------------------------------------------------------------
# Public: metrics config
# ---------------------------------------------------------------------------

sub loadTTFMetrics {
	return if $loadedTTFMetrics;

	main::INFOLOG && $log->info("Loading TTF metrics from ttfmetrics.conf");

	for my $dir (graphicsDirs()) {
		next unless -d $dir;

		my $file = catdir($dir, 'ttfmetrics.conf');
		next unless -r $file;

		my @lines = eval { read_file($file) };
		next if $@;

		my $section = undef;

		for my $line (@lines) {
			chomp $line;
			$line =~ s/\r$//;
			next if $line =~ /^\s*(?:#|$)/;

			# [ttf:filename.ttf] — section header
			if ($line =~ /^\[\s*ttf\s*:\s*(.+?)\s*\]$/i) {
				$section = $1;
				next;
			}

			next unless defined $section;

			# alias * <other-ttf>  — whole-section alias
			if ($line =~ /^\s*alias\s+\*\s+(\S+)/i) {
				$ttfSectionAlias{$section} = $1;
				next;
			}

			# uc <bmp-font>
			if ($line =~ /^\s*uc\s+(\S+)/i) {
				$ttfUCByFile{$section}{$1} = 1;
				next;
			}

			# no-uc <bmp-font>
			if ($line =~ /^\s*no-uc\s+(\S+)/i) {
				$ttfNoUCByFile{$section}{$1} = 1;
				next;
			}

			# alias <new-bmp> <existing-bmp>
			if ($line =~ /^\s*alias\s+(\S+)\s+(\S+)/i) {
				$ttfAliasesByFile{$section}{$1} = $2;
				next;
			}

			# <bmp-font> <FTFontSize> <FTBaseline>
			my ($bmp, $sz, $bl) = split /\s+/, $line;
			next unless $bmp && defined $sz && defined $bl;
			next unless $sz =~ /^\d+$/ && $bl =~ /^\d+$/;
			$ttfMetricsByFile{$section}{$bmp} = { FTFontSize => int($sz), FTBaseline => int($bl) };
		}
	}

	$loadedTTFMetrics = 1;
}

# Resolve whole-section alias chain, guarding against loops.
sub _resolveTTFSection {
	my ($base) = @_;
	my %seen;
	while (defined $base && !$seen{$base}++) {
		return $base unless exists $ttfSectionAlias{$base};
		$base = $ttfSectionAlias{$base};
	}
	return $base;
}

# Look up a bmp font name within one TTF section, following intra-section aliases.
sub _lookupInSection {
	my ($section, $bmpFont) = @_;
	return unless defined $section && exists $ttfMetricsByFile{$section};
	my $m       = $ttfMetricsByFile{$section};
	my $aliases = $ttfAliasesByFile{$section} || {};

	return $m->{$bmpFont} if exists $m->{$bmpFont};

	my $target = $aliases->{$bmpFont};
	return $m->{$target} if $target && exists $m->{$target};

	if ($bmpFont =~ /(\.[12])$/) {
		my $wc = '*' . $1;
		return $m->{$wc} if exists $m->{$wc};
		return $m->{$aliases->{$wc}} if $aliases->{$wc} && exists $m->{$aliases->{$wc}};
	}

	return;
}

# Return { FTFontSize, FTBaseline } for the given BMP font name,
# using the currently active TTF font's section in the config.
sub ttfMetricsForFont {
	my ($bmpFont) = @_;
	return unless $bmpFont;

	loadTTFMetrics();

	my $ttfBase = _ttfBaseName();

	# 1. Per-TTF section in config
	if ($ttfBase) {
		my $e = _lookupInSection($ttfBase, $bmpFont);
		if ($e) {
			_logTTFMetricsSelection($bmpFont, $ttfBase, "section:$ttfBase", $e);
			return $e;
		}
	}

	# 2. [ttf:*] fallback section in config
	my $e = _lookupInSection('*', $bmpFont);
	if ($e) {
		_logTTFMetricsSelection($bmpFont, $ttfBase, 'section:*', $e);
		return $e;
	}

	_logTTFMetricsSelection($bmpFont, $ttfBase, 'none', undef);

	return;
}

# Return 1 if the given BMP font should be uppercased for the active TTF font.
sub ttfUCForFont {
	my ($bmpFont) = @_;
	return 0 unless $bmpFont && $TTFFontFile;

	loadTTFMetrics();

	my $ttfBase = _ttfBaseName();

	# Check for explicit no-uc directive first (takes precedence)
	for my $section ($ttfBase, '*') {
		next unless defined $section;
		return 0 if exists $ttfNoUCByFile{$section} && $ttfNoUCByFile{$section}{$bmpFont};
	}

	# Then check for uc directive
	for my $section ($ttfBase, '*') {
		next unless defined $section;
		return 1 if exists $ttfUCByFile{$section} && $ttfUCByFile{$section}{$bmpFont};
	}

	return 0;
}

# ---------------------------------------------------------------------------
# Public: character rendering
# ---------------------------------------------------------------------------

# Render a single Unicode code point via FreeType.
# Returns the packed column-major bitmap string, or undef if rendering fails.
sub renderCharTTF {
	my ($ord, $FTFontSize, $FTBaseline) = @_;
	return unless $TTFFontFile && $FTFontSize && defined $FTBaseline;

	return unless canUseFreeType();

	my $cacheKey  = "$FTFontSize.$FTBaseline.$ord";
	my $char_bits = $useTTFGlyphCache ? $TTFCache{$cacheKey} : undef;

	if (!$char_bits) {
		$ft ||= Font::FreeType->new->face($TTFFontFile);
		my $currentRenderKey = join('|', $TTFFontFile, $FTFontSize, $FTBaseline);

		if (!defined $lastLoggedTTFRenderKey || $lastLoggedTTFRenderKey ne $currentRenderKey) {
			main::INFOLOG && $log->info("Rendering with TrueType: $TTFFontFile (size=$FTFontSize baseline=$FTBaseline)");
			$lastLoggedTTFRenderKey = $currentRenderKey;
		}

		my $bits_tmp = '';

		$ft->set_char_size($FTFontSize, $FTFontSize, 96, 96);
		my $glyph = $ft->glyph_from_char_code($ord)
		         || $ft->glyph_from_char_code(9647);  # U+25AF WHITE VERTICAL RECTANGLE as fallback
		my ($bmp, $left, $top) = $glyph->bitmap(FT_RENDER_MODE_MONO);
		my $width  = length $bmp->[0];
		my $height = scalar @{$bmp};

		my $top_padding = $FTBaseline - $top;
		my $start_y = 0;
		if ($top_padding < 0) {
			$start_y    = abs($top_padding);
			$top_padding = 0;
		}

		if ($height + $top_padding > 32) {
			$height = 32 - $top_padding;
		}

		my $bottom_padding = 32 - $height - $top_padding + $start_y;
		$bottom_padding = 0 if $bottom_padding < 0;

		for (my $x = 0; $x < $glyph->left_bearing;  $x++) { $bits_tmp .= '0' x 32; }

		for (my $x = 0; $x < $width; $x++) {
			$bits_tmp .= '0' x $top_padding;
			for (my $y = $start_y; $y < $height; $y++) {
				$bits_tmp .= (substr $bmp->[$y], $x, 1) eq "\xFF" ? 1 : 0;
			}
			$bits_tmp .= '0' x $bottom_padding;
		}

		for (my $x = 0; $x < $glyph->right_bearing; $x++) { $bits_tmp .= '0' x 32; }

		$char_bits = pack "B*", $bits_tmp;
		$TTFCache{$cacheKey} = $char_bits if $useTTFGlyphCache;
	}

	return $char_bits;
}

1;

__END__
