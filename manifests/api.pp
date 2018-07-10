# Installs & configure the aodh api service
#
# == Parameters
#
# [*enabled*]
#   (optional) Should the service be enabled.
#   Defaults to true
#
# [*manage_service*]
#   (optional) Whether the service should be managed by Puppet.
#   Defaults to true.
#
# [*package_ensure*]
#   (optional) ensure state for package.
#   Defaults to 'present'
#
# [*service_name*]
#   (optional) Name of the service that will be providing the
#   server functionality of aodh-api.
#   If the value is 'httpd', this means aodh-api will be a web
#   service, and you must use another class to configure that
#   web service. For example, use class { 'aodh::wsgi::apache'...}
#   to make aodh-api be a web app using apache mod_wsgi.
#   Defaults to '$::aodh::params::api_service_name'
#
# [*sync_db*]
#   (optional) Run gnocchi-upgrade db sync on api nodes after installing the package.
#   Defaults to false
#
# [*auth_strategy*]
#   (optional) Type of authentication to be used.
#   Defaults to 'keystone'
#
# [*enable_proxy_headers_parsing*]
#   (Optional) Enable paste middleware to handle SSL requests through
#   HTTPProxyToWSGI middleware.
#   Defaults to $::os_service_default.
#
# [*paste_config*]
#   (Optional) Configuration file for WSGI definition of API
#   Defaults to $::os_service_default.
#
# [*gnocchi_external_project_owner*]
#   (optional) Gnocchi external project owner (usually Ceilometer project name)
#   Defaults to 'services'
#
# DEPRECATED PARAMETERS
#
# [*host*]
#   (optional) The aodh api bind address.
#   Defaults to undef
#
# [*port*]
#   (optional) The aodh api port.
#   Defaults to undef
#
class aodh::api (
  $manage_service                 = true,
  $enabled                        = true,
  $package_ensure                 = 'present',
  $service_name                   = $::aodh::params::api_service_name,
  $sync_db                        = false,
  $auth_strategy                  = 'keystone',
  $enable_proxy_headers_parsing   = $::os_service_default,
  $paste_config                   = $::os_service_default,
  $gnocchi_external_project_owner = 'services',
  # DEPRECATED PARAMETERS
  $host                           = undef,
  $port                           = undef,
) inherits aodh::params {


  include ::aodh::deps
  include ::aodh::params
  include ::aodh::policy

  if $auth_strategy == 'keystone' {
    include ::aodh::keystone::authtoken
  }

  if $host {
    warning('host has no effect as of Newton and will be removed in a future \
release. aodh::wsgi::apache supports setting a host via bind_host.')
  }
  if $port {
    warning('port has no effect as of Newton and will be removed in a future \
release. aodh::wsgi::apache supports setting a port.')
  }

  package { 'aodh-api':
    ensure => $package_ensure,
    name   => $::aodh::params::api_package_name,
    tag    => ['openstack', 'aodh-package'],
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  if $sync_db {
    include ::aodh::db::sync
  }

  if $service_name == $::aodh::params::api_service_name {
    service { 'aodh-api':
      ensure     => $service_ensure,
      name       => $::aodh::params::api_service_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      tag        => 'aodh-service',
    }
  } elsif $service_name == 'httpd' {
    include ::apache::params
    service { 'aodh-api':
      ensure => 'stopped',
      name   => $::aodh::params::api_service_name,
      enable => false,
      tag    => 'aodh-service',
    }

    # we need to make sure aodh-api/eventlet is stopped before trying to start apache
    Service['aodh-api'] -> Service[$::apache::params::service_name]
    # the apache service is untagged so add it to the service section manually
    Anchor['aodh::service::begin'] ~> Service[$::apache::params::service_name]
  } else {
    fail("Invalid service_name. Either aodh/openstack-aodh-api for running \
as a standalone service, or httpd for being run by a httpd server")
  }

  aodh_config {
    'api/gnocchi_external_project_owner': value => $gnocchi_external_project_owner;
    'api/paste_config':                   value => $paste_config;
  }

  oslo::middleware { 'aodh_config':
    enable_proxy_headers_parsing => $enable_proxy_headers_parsing,
  }
}
