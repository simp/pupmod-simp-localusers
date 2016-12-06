# This class provides the ability to provide local users (or any other type of
# user) to all of your clients.
#
# This is only needed if the native Puppet type cannot manage passwords on your
# systems.
#
# @param source Source of the localusers file. See lib/puppet/parser/function for syntax.
#
# @param localusers Additional users, floowing the same syntax from the file.
#
class localusers (
  Stdlib::AbsolutePath $source = "${::settings::environmentpath}/${::environment}/localusers",
  Array $localusers            = []
) {

  # Read the source and find a list of users to manage
  $_localusers = localuser($source, $::fqdn) + $localusers
  inspect(localuser($source, $::fqdn))
  inspect($_localusers)

  file { '/usr/local/sbin/simp/localusers.rb':
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template('localusers/localusers.rb.erb'),
    tag     => 'firstrun',
    notify  => Exec['modify_local_users']
  }

  exec { 'modify_local_users':
    command     => '/usr/local/sbin/simp/localusers.rb',
    path        => '/bin:/usr/sbin',
    refreshonly => true,
    tag         => 'firstrun'
  }
}
