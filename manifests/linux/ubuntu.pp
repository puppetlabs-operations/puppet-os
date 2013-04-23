class os::linux::ubuntu {

  include os::linux::debian

  # On older, deprecated, dying Ubuntus we have to use
  # http://old-releases.ubuntu.com/ for their apt sources.
  # This is making special cases for things that _should_ go away, but
  # on the flip side, there's no harm to it, and other releases may
  # disappear in the future.
  case $lsbdistcodename {
    'karmic': {
      $main_apt_host     = 'http://old-releases.ubuntu.com/'
      $security_apt_host = 'http://old-releases.ubuntu.com/'
    }
    default: {
      $main_apt_host     = 'http://us.archive.ubuntu.com/'
      $security_apt_host = 'http://security.ubuntu.com/'
    }
  }

  apt::source { "main":
      location => "${main_apt_host}/ubuntu/",
      repos    => "main restricted universe"
  }

  apt::source { "security_updates":
      location => "${security_apt_host}/ubuntu/",
      release  => "${lsbdistcodename}-updates",
      repos    => "main restricted universe",
  }

}
