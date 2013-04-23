class os {
  case $::kernel {
    linux:   { include os::linux }
    darwin:  { include os::darwin }
    freebsd: { include os::freebsd }
    sunos:   { include os::solaris }
    solaris: { include os::solaris }
    junos:   { }
    default: { notify { "OS ${operatingsystem} has no love": } }
  }
}
