# vim: set expandtab sw=2 ts=2 ci :
class alice_xrootd::service  {
  $role = $alice_xrootd::is_manager ? {
    true    => 'manager',
    default => 'server',
  }

  if $alice_xrootd::service_manage {
    service {
      [
        'mlsensor',
        "xrootd@${role}",
        "cmsd@${role}"
      ]:
        ensure => $alice_xrootd::service_ensure,
        enable => $alice_xrootd::service_enable;
      }
  }
}
