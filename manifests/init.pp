class nginx (
  $user = 'www-data',
  $worker_processes = 16,
  $worker_connections = 1024
) {

  package {'nginx':
    ensure => present,
  }

  exec {'remove nginx from rc.d':
    command => "/usr/sbin/update-rc.d -f nginx remove",
    refreshonly => true
  }

  # hack to not create dependency cycle
  exec { 'remove nginx config file':
    command => 'rm /etc/init.d/nginx',
    path => "/bin",
    refreshonly => true,
    notify => Exec['remove nginx from rc.d']
  }

  exec {'stop nginx':
    command => "/etc/init.d/nginx stop",
    path => "/root",
    onlyif => '/bin/ls /etc/init.d/nginx',
    notify => Exec['remove nginx config file']
  }

  file {'/etc/init/nginx.conf':
    owner => 'root',
    group => 'root',
    mode => 'u=rw,go=r',
    notify => Service['nginx'],
    content => template("${module_name}/nginx.conf.erb"),
  }

  file {'/etc/nginx/nginx.conf':
    owner => 'root',
    group => 'root',
    mode => 'u=rw,go=r',
    notify => Service['nginx'],
    content => template("${module_name}/nginx.erb"),
  }

  service {'nginx':
    ensure => running,
    provider => upstart
  }

  Package['nginx'] -> Exec['stop nginx'] -> File['/etc/init/nginx.conf'] -> File['/etc/nginx/nginx.conf']

}