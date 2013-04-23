class os::darwin {

  $opt_root = "/opt/operations"

  # Work around hiera fail. If these values are not given then hiera pukes out
  # some error about getting a symbol when expected a string, I'm assuming that
  # this is :undef being passed to something that isn't smart enough to handle
  # it. Remove the extraneous settings when hiera/puppet is less damaged.
  #
  # macports::install::source depends on the staging module.
  class { 'staging':
    path  => "${opt_root}/tmp",
    owner => '0',
    group => '0',
    mode  => '0755',
  }

  class { 'macports::install::source':
    prefix  => $opt_root,
    version => '2.1.2',
  }

  # Patch puppet to use /opt/operations. God this is dirty, but it's how PE does it.
  file {
    "${opt_root}/lib/ruby/site_ruby/1.8/puppet/reference/configuration.rb":
      ensure  => present,
      source  => 'puppet:///modules/os/darwin/configuration.rb',
      mode    => '644',
      owner   => 'root',
      group   => 'admin',
      require => Package['puppet'];
    "${opt_root}/lib/ruby/site_ruby/1.8/puppet/util/run_mode.rb":
      ensure => present,
      source => 'puppet:///modules/os/darwin/run_mode.rb',
      mode   => '644',
      owner  => 'root',
      group  => 'admin',
      require => Package['puppet'];
  }

  # For all machines that have /opt/operations, install a .profile for root
  # that adds /opt/operations/bin to the front of $PATH
  file { '/var/root/.profile':
    ensure => present,
    owner  => 0,
    group  => 0,
    mode   => '0644',
    source => 'puppet:///modules/os/darwin/_profile',
  }

  # Set default package provider to puppet labs operations macports
  Package { provider => 'plorts' }

  include ruby

  # I think this needs to be manually set. revisit?
  package { ['puppet', 'facter']:
    ensure   => latest,
    provider => plorts,
  }
}
