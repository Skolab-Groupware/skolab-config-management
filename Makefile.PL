use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use Getopt::Long;

my $VERSION;
my $KOLAB_VERSION;

# The Kolab version number for the perl-kolab package
my $KOLAB_BASE_VERSION = "2.2.0";

# Are current releases cvs based or is this a real release?
my $KOLAB_CVS = 0;

my $KOLAB_RELEASE = sprintf "%0004d%02d%02d", ((gmtime)[5] + 1900), ((gmtime)[4] + 1), (gmtime)[3];

if ($KOLAB_CVS) {
    $KOLAB_VERSION = $KOLAB_BASE_VERSION . "+cvs";
    $VERSION = $KOLAB_VERSION . $KOLAB_RELEASE;
} else {
    $KOLAB_VERSION = $KOLAB_BASE_VERSION;
    $VERSION = $KOLAB_VERSION;
}

my $HELP = 0;
my $CONFIG = '/kolab/etc/kolab/kolab.globals';
my $INSTALLSCRIPT = '/kolab/sbin';

GetOptions(
    "config=s" => \$CONFIG,
    "bin=s" => \$INSTALLSCRIPT,
    "help" => \$HELP
    );

if ($HELP) {
  print <<'EOH';
Usage: perl Makefile.PL [--config CONFIG_FILE] [--bin BIN_DIR] --help

Option config

  to specify the path to the kolab.globals configuration file. The
  default is /kolab/etc/kolab/kolab.globals but this may vary
  depending on your installation.

Option bin

  to specify the path to the directory where the kolabconf script
  should be installed.

Option help

  to get this text.

EOH
exit 0;
}

# Add the dist_openpkg target to the dist target
sub MY::dist {
    package MY;   # To help SUPER work right
    my $self = shift;
    my @m;
    
    push(@m, $self->SUPER::dist(@_));
    
    my $dist = join "", @m;

    $dist =~ s/(tardist.*)/clean_tardist $1 dist_openpkg/;
     
    return $dist;
}

# Remove additional files
sub MY::veryclean {
    package MY;   # To help SUPER work right
    my $self = shift;
    my @m;
    
    push(@m, $self->SUPER::clean(@_));
    
    my $clean = join "", @m;

    $clean =~ s/(clean.*)/$1 clean_openpkg clean_scripts/;
     
    return $clean;
}

sub MY::postamble {
    
    my $add = ".PHONY: bin/kolabconf
bin/kolabconf: bin/kolabconf.in
	cat \$< | sed -e 's#\@CONFIG_FILE@#$CONFIG#' | sed -e 's#\@VERSION@#$VERSION#' > \$@

ifeq \"x\$(RPM)\" \"x\"
  RPM = \$(HOME)/bin/openpkg rpm
endif
ifeq \"x\$(KOLABRPMSRC)\" \"x\"
  KOLABRPMSRC = \$(HOME)/RPM/SRC
endif
ifeq \"x\$(KOLABRPMPKG)\" \"x\"
  KOLABRPMPKG = \$(HOME)/RPM/PKG
endif
ifeq \"x\$(KOLABRPMTMP)\" \"x\"
  KOLABRPMTMP = \$(HOME)/RPM/TMP
endif

PACKAGE = \$(shell [ -r \"kolabconf.spec\" ] && grep '%define[ ]*V_package' kolabconf.spec | sed -e 's/.*V_package\\s*\\([a-z\\-\\_]*\\).*/\\1/')
VERSION = $KOLAB_VERSION
RELEASE = $KOLAB_RELEASE
SOURCE_TAG = $VERSION

clean_tardist:
	rm -rf *.tar.gz

clean_all: clean_tardist veryclean
	rm -rf bin/kolabconf
	rm -rf \$(KOLABRPMTMP)/\$(PACKAGE)
	rm -rf *.src.rpm
	rm -rf *~

dist_openpkg: kolabconf.spec \$(PACKAGE)-\$(VERSION)-\$(RELEASE).src.rpm
	cp \$(PACKAGE)-\$(VERSION)-\$(RELEASE).src.rpm ../stage/

\$(PACKAGE)-\$(VERSION)-\$(RELEASE).src.rpm: \$(PACKAGE).spec
	test -d \$(KOLABRPMSRC)/\$(PACKAGE) || mkdir \$(KOLABRPMSRC)/\$(PACKAGE)
	cp \$(PACKAGE).spec \$(PACKAGE).spec.tmp
	sed -i -e 's/\@VERSION\@/\$(VERSION)/' \$(PACKAGE).spec.tmp
	sed -i -e 's/\@RELEASE\@/\$(RELEASE)/' \$(PACKAGE).spec.tmp
	sed -i -e 's/\@SOURCE_TAG\@/\$(SOURCE_TAG)/' \$(PACKAGE).spec.tmp
	mv \$(PACKAGE).spec.tmp \$(KOLABRPMSRC)/\$(PACKAGE)/\$(PACKAGE).spec
	mv \$(PACKAGE)-\$(SOURCE_TAG).tar.gz \$(KOLABRPMSRC)/\$(PACKAGE)
	cd \$(KOLABRPMSRC)/\$(PACKAGE) && \$(RPM) -ba \$(PACKAGE).spec
	cp -p \$(KOLABRPMPKG)/\$(PACKAGE)-\$(VERSION)-\$(RELEASE).src.rpm .

";

    return $add;
}

# older versions of ExtUtils:MakeMaker don't support INSTALLVENDORSCRIPT
my $installscript = "";
if ($ExtUtils::MakeMaker::VERSION >= 6.42) {
    $installscript = "INSTALLVENDORSCRIPT";
} else {
    $installscript = "INSTALLSCRIPT";
}

WriteMakefile(
    NAME              => 'kolabconf',
    VERSION           => $VERSION,
    INSTALLDIRS       => 'vendor',
    EXE_FILES         => [ 'bin/kolabconf', ],
    $installscript    => $INSTALLSCRIPT,
    ABSTRACT          => 
'kolabconf provides the central mechanism to the configuration concept
of the Kolab server. It rewrites the Kolab configuration templates
into the final configuration files and handles the necessary magic
associated to that process.',
    AUTHOR            => 'Stuart Bingë and others (see AUTHORS file)'
    );
