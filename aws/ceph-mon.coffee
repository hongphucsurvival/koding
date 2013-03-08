aws = (require 'koding-aws').aws

findNextName = (callback) ->
  params =
    Filters: [
      Name: 'tag:ceph-type'
      Values: ['mon']
    ]

  ec2 = new aws.EC2.Client()
  ec2.describeInstances params, (err, data) ->
    if err
      callback err, ''
    cephMonitors = []
    for res in data.Reservations
      for ins in res.Instances
        for tag in ins.Tags
          if tag.Key == 'ceph-id'
            cephMonitors.push tag.Value.charCodeAt(0)
    cephMonitors.sort()
    cephMonitors.reverse()

    if cephMonitors.length == 0
      nextName = 'a'
    else
      nextName = String.fromCharCode(cephMonitors[0] + 1)

    callback no, nextName


buildTemplate = (callback) ->
  findNextName (err, nextName) ->
    if err
      callback err, ''
      return

    template =
      type          : 'm1.medium'
      ami           : 'ami-de0d9eb7'
      key           : 'koding'
      tags          :
        Name        : "ceph-mon-#{nextName}-test"
        ceph_type   : 'mon'
        ceph_id     : nextName 
      userData      : """
                      #!/bin/bash
                      /bin/hostname #{nextName}.beta.system.aws.koding.com
                      echo "127.0.0.1 $(hostname)" | tee /etc/hosts -a
                      set -e -x
                      LOGFILE="/var/log/user-data-out.log"
                      mkdir -p /etc/chef
                      cat > /root/.s3cfg << "EOF"
                      [default]
                      access_key = AKIAJO74E23N33AFRGAQ
                      bucket_location = US
                      cloudfront_host = cloudfront.amazonaws.com
                      cloudfront_resource = /2010-07-15/distribution
                      default_mime_type = binary/octet-stream
                      delete_removed = False
                      dry_run = False
                      encoding = UTF-8
                      encrypt = False
                      follow_symlinks = False
                      force = False
                      get_continue = False
                      guess_mime_type = True
                      host_base = s3.amazonaws.com
                      host_bucket = %(bucket)s.s3.amazonaws.com
                      human_readable_sizes = False
                      list_md5 = False
                      log_target_prefix = 
                      preserve_attrs = True
                      progress_meter = True
                      proxy_host = 
                      proxy_port = 0
                      recursive = False
                      recv_chunk = 4096
                      reduced_redundancy = False
                      secret_key = kpKvRUGGa8drtLIzLPtZnoVi82WnRia85kCMT2W7
                      send_chunk = 4096
                      simpledb_host = sdb.amazonaws.com
                      skip_existing = False
                      socket_timeout = 10
                      urlencoding_mode = normal
                      use_https = True
                      verbosity = WARNING
                      EOF
                      export DEBIAN_FRONTEND=noninteractive
                      echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
                      apt-get update >> $LOGFILE
                      apt-get -y --force-yes install opscode-keyring >> $LOGFILE
                      apt-get -y upgrade >> $LOGFILE
                      apt-get -y install s3cmd chef --force-yes >> $LOGFILE
                      /usr/bin/s3cmd --config /root/.s3cfg get s3://chef-conf/ceph-mon.pem /etc/chef/ceph-mon.pem --force
                      /usr/bin/s3cmd --config /root/.s3cfg get s3://koding-vagrant-Lti5bj61mVnfMkhX/chef-conf/chris-test-validator.pem /etc/chef/chris-test-validator.pem --force
                      /usr/bin/s3cmd --config /root/.s3cfg get s3://chef-conf/chrisTest-mon.rb /etc/chef/client.rb --force
                      service chef-client restart

                      """

    callback no, template

module.exports = 
  buildTemplate: buildTemplate
