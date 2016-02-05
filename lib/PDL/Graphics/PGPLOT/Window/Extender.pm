package PGPLOT::Extender;
use Moose;
use Data::Dumper;

extends 'PDL::Graphics::PGPLOT::Window';

around 'cursor' => sub {
  my $func = shift;
  my $self = shift;
  my @click = $self->$func(@_);
  if ($click[2] =~ /Q|q/) {
    $self->close();
    # Kill PGPLOT Session
    `killall pgxwin_server`;
    die "Exiting\n";
  };
  return @click;
};

has 'history'	=> (
  is    	=> 'rw',
  isa   	=> 'ArrayRef',
  traits 	=> ['Array'],
  handles	=> {
	add_hist 	=> 'push',
	clear_hist	=> 'clear',
	count_hist	=> 'count',
	rem_hist	=> 'pop',
	get_hist	=> 'get',
  },
);

for my $func ( qw/rect env text line fits_imag/ ) {
  before $func => sub {
    my $self = shift;
    $self->add_hist([$func,\@_]);
  };
}

before 'points' => sub {
  my $self = shift;
  my $x =  sprintf "%.3f", $_[0];
  my $y =  sprintf "%.3f", $_[1];
  $self->add_hist(['points',[$x,$y,$_[2]]]);
};

after 'env' => sub {
  my $self = shift;
  $self->hold();
};

after 'fits_imag' => sub {
  my $self = shift;
  my $i = 1;
  my $env = $self->get_hist(-$i);
  $env = $self->get_hist(-$i++) until ($$env[0] eq 'env');
  $self->env(@{$$env[1]});
  $self->del_hist();
};

around 'close' => sub {
  my $func = shift;
  my $self = shift;
  $self->clear_hist();
  return $self->$func();
};

sub plot_hist {
  my $self = shift;
  my $hist = @_ ? $_[0] : $self->ret_hist();
  $self->env(0, 1, 0, 1,{PlotPosition => [0,1,0,1],axis=>-2});
  $self->rect( 0,1,0,1,{color=>'white',filltype=>1});
  $self->del_hist(2);
  $self->clear_hist();
  my @list = @{$hist};
  for my $step (@list) {
    my ($com,$opt) = @{$step};
    $self->$com( @{$opt});
  }
}

sub set_hist {
  my $self = shift;
  my $hist = shift;
  $self->clear_hist();
  $self->add_hist(@{$hist});
}

sub ret_hist {
  my $self = shift;
  return [@{ $self->history() }];
}

sub del_hist {
  my $self = shift;
  my $items = shift || 1;
  $self->rem_hist() for (1..$items);
}

1;
