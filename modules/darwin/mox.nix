{ config, lib, pkgs, ... }:

with lib;

let
cfg = config.mox;
moxies = pkgs.moxies;

moxieService = name: {
  command = toString moxies."${name}".entry;
  stdout_logfile = "/tmp/mox.${name}.log";
};

in

{
  options = {
  };

  config = {
    supervisord.programs.nginx = moxieService "nginx";
    supervisord.programs.mysql = moxieService "mysql";
    supervisord.programs.redis = moxieService "redis";
    supervisord.programs.memcached = moxieService "memcached";
  };
}
