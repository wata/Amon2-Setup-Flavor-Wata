package Amon2::Setup::Flavor::Wata;
use strict;
use warnings;
our $VERSION = '0.01';

use parent qw(Amon2::Setup::Flavor::Minimum);
use Amon2::Setup::Asset::jQuery;
use Amon2::Setup::Asset::BlueTrip;
use HTTP::Status qw/status_message/;
use utf8;
use File::Copy;

sub run {
    my $self = shift;

    $self->SUPER::run();

    $self->mkpath('static/img/');
    $self->mkpath('static/js/');

    $self->write_file('lib/<<PATH>>.pm', <<'...');
package <% $module %>;
use strict;
use warnings;
use parent qw/Amon2/;
our $VERSION='0.01';
use 5.008001;

# __PACKAGE__->load_plugin(qw/DBI/);

1;
...

    $self->write_file('lib/<<PATH>>/Web.pm', <<'...');
package <% $module %>::Web;
use strict;
use warnings;
use parent qw/<% $module %> Amon2::Web/;
use File::Spec;

# load all controller classes
use Module::Find ();
Module::Find::useall("<% $module %>::Web::C");

# dispatcher
use <% $module %>::Web::Dispatcher;
sub dispatch {
    return <% $module %>::Web::Dispatcher->dispatch($_[0]) or die "response is not generated";
}

# setup view class
use Text::Xslate;
{
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'} || +{};
    unless (exists $view_conf->{path}) {
        $view_conf->{path} = [ File::Spec->catdir(__PACKAGE__->base_dir(), 'tmpl') ];
    }
    my $view = Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
        },
        %$view_conf
    });
    sub create_view { $view }
}

# load plugins
use HTTP::Session::Store::File;
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::NoCache', # do not cache the dynamic content by default
    'Web::CSRFDefender',
    'Web::HTTPSession' => {
        state => 'Cookie',
        store => HTTP::Session::Store::File->new(
            dir => File::Spec->tmpdir(),
        )
    },
);

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
    },
);

__PACKAGE__->add_trigger(
    BEFORE_DISPATCH => sub {
        my ( $c ) = @_;
        # ...
        return;
    },
);

1;
...

    $self->write_file("lib/<<PATH>>/Web/Dispatcher.pm", <<'...');
package <% $module %>::Web::Dispatcher;
use strict;
use warnings;
use Amon2::Web::Dispatcher::Lite;

any '/' => sub {
    my ($c) = @_;
    $c->render('index.tt');
};

1;
...

    $self->write_file("config/development.pl", <<'...');
+{
    'DBI' => [
        'dbi:SQLite:dbname=development.db',
        '',
        '',
        +{
            sqlite_unicode => 1,
        }
    ],
};
...

    $self->write_file("config/deployment.pl", <<'...');
+{
    'DBI' => [
        'dbi:SQLite:dbname=deployment.db',
        '',
        '',
        +{
            sqlite_unicode => 1,
        }
    ],
};
...

    $self->write_file("config/test.pl", <<'...');
+{
    'DBI' => [
        'dbi:SQLite:dbname=test.db',
        '',
        '',
        +{
            sqlite_unicode => 1,
        }
    ],
};
...

    $self->write_file("sql/my.sql", '');
    $self->write_file("sql/sqlite3.sql", '');

    $self->write_file('tmpl/index.tt', <<'...');
[% WRAPPER 'include/layout.tt' %]

<hr class="space">

<div id="content" class="span-17 colborder">
    <h2>Let's get started!</h2>
    <p>description...</p>
</div>

<div id="side" class="span-6 last">
    <h3 class="thin">Side menu</h3>
    <ul>
    <li>
        <a href="http://twitter.com/share" class="twitter-share-button" data-url="http://amon.64p.org/" data-text="Amon2 - Web application framework for Rapid web development — Amon2 v documentation" data-count="horizontal" data-lang="ja">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
    </li>
    <li>
        <iframe src="http://www.facebook.com/plugins/like.php?href=[% 'http://amon.64p.org/' | uri %]&amp;layout=button_count&amp;show_faces=true&amp;width=108&amp;action=like&amp;font=lucida+grande&amp;colorscheme=light&amp;height=21" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:108px; height:21px;" allowTransparency="true"></iframe>
    </li>
    <li>
        <a href="http://b.hatena.ne.jp/entry/http://amon.64p.org/" class="hatena-bookmark-button" data-hatena-bookmark-title="Amon2 - Web application framework for Rapid web development — Amon2 v documentation" data-hatena-bookmark-layout="standard" title="このエントリーをはてなブックマークに追加"><img src="http://b.st-hatena.com/images/entry-button/button-only.gif" alt="このエントリーをはてなブックマークに追加" width="20" height="20" style="border: none;" /></a><script type="text/javascript" src="http://b.st-hatena.com/js/bookmark_button.js" charset="utf-8" async="async"></script>
    </li>
    </ul>
</div>

<hr class="space">

[% END %]
...

    $self->{jquery_min_basename} = Amon2::Setup::Asset::jQuery->jquery_min_basename();
    $self->write_file('tmpl/include/layout.tt', <<'...');
<!doctype html">
<html lang="ja"">
<head>
    <meta charset=utf-8" />
    <title>[% title || '<%= $dist %>' %]</title>
    <meta name="Author" content="<%= $dist %>" />
    <meta name="Keywords" content="<%= $dist %>" />
    <meta name="Description" content="<%= $dist %>" />
    <meta name="format-detection" content="telephone=no" />
    <link href="[% uri_for('/static/css/screen.css') %]" rel="stylesheet" type="text/css" media="screen" />
    <link href="[% uri_for('/static/css/print.css') %]" rel="stylesheet" type="text/css" media="print" />
    <!--[if lt IE 8]><link rel="stylesheet" href="[% uri_for('/static/css/ie.css') %]" type="text/css" media="screen, projection"><![endif]-->
    <link href="[% uri_for('/static/css/style.css') %]" rel="stylesheet" type="text/css" media="screen" />
    <script src="[% uri_for('/static/js/<% $jquery_min_basename %>') %]"></script>
    <!--[if lt IE 9]>
        <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
</head>
<body[% IF bodyID %] class="[% bodyID %]"[% END %]>
    <div class="container">
        <div id ="header" class="span-24 large fancy">
            <h1><a href="[% uri_for('/') %]"><%= $dist %></a></h1>
        </div>
        <div id="wrapper" class="span-24">
            [% content %]
        </div>
        <div id="footer">
            <address>&copy; <%= $dist %></address>
        </div>
    </div>
</body>
</html>
...

    $self->write_file('static/js/' . Amon2::Setup::Asset::jQuery->jquery_min_basename(), Amon2::Setup::Asset::jQuery->jquery_min_content());
    $self->_cp(Amon2::Setup::Asset::BlueTrip->bluetrip_path, 'static/');

    $self->write_file("t/00_compile.t", <<'...');
use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
    <% $module %>
    <% $module %>::Web
    <% $module %>::Web::Dispatcher
);

done_testing;
...

    $self->write_file("xt/02_perlcritic.t", <<'...');
use strict;
use Test::More;
eval q{
	use Perl::Critic 1.113;
	use Test::Perl::Critic 1.02 -exclude => [
		'Subroutines::ProhibitSubroutinePrototypes',
		'Subroutines::ProhibitExplicitReturnUndef',
		'TestingAndDebugging::ProhibitNoStrict',
		'ControlStructures::ProhibitMutatingListFunctions',
	];
};
plan skip_all => "Test::Perl::Critic 1.02+ and Perl::Critic 1.113+ is not installed." if $@;
all_critic_ok('lib');
...

    $self->write_file('.gitignore', <<'...');
Makefile
inc/
MANIFEST
*.bak
*.old
nytprof.out
nytprof/
development.db
test.db
...

    for my $status (qw/404 500 502 503 504/) {
        $self->write_status_file("static/$status.html", $status);
    }
}

sub write_status_file {
    my ($self, $fname, $status) = @_;

    local $self->{status}         = $status;
    local $self->{status_message} = status_message($status);
 
    $self->write_file($fname, <<'...');
<!doctype html> 
<html> 
    <head> 
        <meta charset=utf-8 /> 
        <style type="text/css"> 
            body {
                text-align: center;
                font-family: 'Menlo', 'Monaco', Courier, monospace;
                background-color: whitesmoke;
                padding-top: 10%;
            }
            .number {
                font-size: 800%;
                font-weight: bold;
                margin-bottom: 40px;
            }
            .message {
                font-size: 400%;
            }
        </style> 
    </head> 
    <body> 
        <div class="number"><%= $status %></div> 
        <div class="message"><%= $status_message %></div> 
    </body> 
</html> 
...
}

sub _cp {
    my ($self, $from, $to) = @_;
    system("cp -Rp $from $to") == 0
        or die "external cp command status was $?";
}

1;
__END__

=head1 NAME

Amon2::Setup::Flavor::Wata -

=head1 SYNOPSIS

  use Amon2::Setup::Flavor::Wata;

=head1 DESCRIPTION

Amon2::Setup::Flavor::Wata is

=head1 AUTHOR

Wataru Nagasawa E<lt>nagasawa {at} junkapp.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
