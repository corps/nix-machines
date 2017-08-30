require 'erb'
require 'json'
require 'fileutils'
require 'pp'

json = JSON.parse(`nix-instantiate --json --eval --strict --expr '(import ./plugins.nix { pkgs.vimUtils.buildVimPluginFrom2Nix = { name, ... }: name; fetchFromGitHub = null; })'`)

names = json.keys.sort

File.write('configuration.nix.tmp', ERB.new(<<-TEMPLATE, 1, '<->').result)
{ pkgs }:
let plugins = pkgs.callPackage ./plugins.nix {};
in {
  customRC = ''${builtins.readFile ./vimrc}'';
  vam = {
    knownPlugins = pkgs.vimPlugins // plugins;
    pluginDictionaries = [{
      names = [
   <% names.each do |name| -%>
     <%= name.dump %>
   <% end -%>   ];
    }];
  };
}
TEMPLATE

FileUtils.mv('configuration.nix.tmp', 'configuration.nix')
