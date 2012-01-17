package WWW::BTjunkie;

use Any::Moose;
use Data::Dumper;
use URI;
use Web::Scraper::LibXML;

=head1 NAME

WWW::BTjunkie - search API for http://btjunkie.org using Web::Scraper::LibXML(*)

(*) which annoyingly creates a lot of noise, due to the HTML::TreeBuilder::LibXML
guys not setting "suppress_errors" or at least giving a chance to pass the
option through when instantiating XML::LibXML, but it's tradeoff for a lot of speed
you'll appreciate i think. just reroute STDERR before and you're fine :D

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Currently only a search method is provided that returns an arrayref of hashes.
Several advanced search options can be used. See ATTRIBUTES

    use WWW::BTjunkie;

    my $bt = WWW::BTjunkie->new->search("weird stuff", { lang => "es", category => "anime" });
    foreach my $t (@{ $bt }) {
        print $t->{title} . ' ' . $t->{url} . $/;
    }

=head1 ATTRIBUTES

=cut

has 'url' => (
    is       => 'ro',
    isa      => 'URI',
    default  => sub { URI->new('http://btjunkie.org') },
    required => 1,
);

=head2 debug

    $bt->is_debug ? say "more" : "nothing";
    $bt->debug(1);
    $bt->no_debug;

get, set or clear debug flag. optional. default: false.

=cut

has 'debug' => (
    is        => 'rw',
    isa       => 'Bool',
    default   => sub{ },
    lazy      => 1,
    predicate => 'is_debug',
    clearer   => 'no_debug',
);

=head2 category

    $bt->category($str);

set/get the category for the search. for possible categories refer to btjunkie.
all category names are case insensitive. optional. default: all.

=cut

has 'category' => (
    is       => 'rw',
    isa      => 'Str',
    default  => sub { 'all' },
);

=head2 lang

    $bt->lang($str);

set/get the 2 character country code as language.
this might change to the actual ISO whatever representation if i feel like it in the future.
for possible values please refer to btjunkie.
this attribute is case insensitive. optional. default: all

=cut

has 'lang' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'all',
);

=head2 order

    $bt->order($str);

set/get the order for each search. possible sort orders are:

    least_seeded_first
    most_seeded_first
    smallest_size_first
    biggest_size_first
    oldest_first
    newest_first

this attribute is case insensitive. optional. default: most_seeded_first

=cut

has 'order' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'most_seeded_first',
);

#has 'scraper' => (
#    is         => 'rw',
#    isa        => 'Web::Scraper',
#    lazy_build => 1,
#);

=head2 trackers

    $bt->trackers($str);

set/get wether "private", "pulic" or "all" types of trackers should be searched.
this attribute is case insensitive. optional. default: all.

=cut

has 'trackers' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'all',
);

=head2 file_scan

    $bt->file_scan($num);

set/get file_scan option. possible values: 1 | 0. optional. default: 0.

=cut

has 'file_scan' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 0 },
    lazy    => 1,
);

my %trackers = (
    all     => 0,
    public  => 1,
    private => 2,
);

my %order = (
    least_seeded_first  => 51,
    most_seeded_first   => 52,
    smallest_size_first => 61,
    biggest_size_first  => 62,
    oldest_first        => 71,
    newest_first        => 72,
);

my %language = (
    all => 0,
    en  => 1,
    nl  => 2,
    fr  => 3,
    it  => 4,
    es  => 5,
    se  => 6,
    de  => 7,
);

my %category = (
    all      => 0,
    audio    => 1,
    games    => 2,
    software => 3,
    tv       => 4,
    unsorted => 5,
    video    => 6,
    anime    => 7,
    xxx      => 8,
);

=head1 METHODS

=head2 search

    $bt->search($str);
    $bt->search($str, $hash)

you can submit any attribute listed above as search option in a hash as an optional second parameter.

    WWW::BTjunkie->new->search('stuff', { lang => 'es', category => 'anime' });

=cut

sub search {
    my ($self, $term, $opts) = @_;
    
    foreach my $key (keys %{ $opts }) {
        $self->$key($opts->{$key});
    }

    my $u = $self->url->clone;
    $u->path('/search');
    $u->query_form(
        q => $term,
        l => $language{ lc($self->lang) },
        c => $category{ lc($self->category) },
        o => $order{ lc($self->order) },
        f => $self->file_scan,
    );
    print "scraping URL: " . $u . $/ if $self->is_debug;

    my $scraper = scraper {
        process ".tab_results > tr[onmouseover]", "results[]" => scraper {
            process "th > table > tr > th > a:first-child", url => '@href';
            process "th > table > tr > th > a.BlckUnd", title => 'TEXT';
            process "//th[2]/a/b", category => 'TEXT';
            process "//th[3]", size => 'TEXT';
            process "//th[4]", date => 'TEXT';
            process "//th[5]", seeders => 'TEXT';
            process "//th[6]", leechers => 'TEXT';
        };
    };
    
    # eliminate eventually empty hashes
    my @results = grep { exists $_->{title} }
        @{ $scraper->scrape($u)->{results} };
    
    print Dumper(\@results) if $self->debug;

    return \@results;
}

=head1 AUTHOR

Tobias Kirschstein, C<< <mail at lev.geek.nz> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-btjunkie at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-BTjunkie>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::BTjunkie


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-BTjunkie>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-BTjunkie>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-BTjunkie>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-BTjunkie/>

=back


=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Tobias Kirschstein.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable();
# End of WWW::BTjunkie

