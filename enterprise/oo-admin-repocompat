#!/usr/bin/env oo-ruby

require 'pp'
require 'getoptlong'

def usage
  puts <<USAGE
== Synopsis

oo-repocompat: Configure yum sources for compatibility with OpenShift

== Usage

oo-repocompat OPTIONS

Options:
--exhaustive
    Generate yum priorities for the full dependency chain (can take several minutes)
--debug
--help
USAGE
  exit 255
end

opts = GetoptLong.new(
    ["--exhaustive",            GetoptLong::NO_ARGUMENT],
    ["--debug",                 GetoptLong::NO_ARGUMENT],
    ["--help",             "-h", GetoptLong::NO_ARGUMENT]
)

args = {}
begin
  opts.each{ |k,v| args[k]=v }
rescue GetoptLong::Error => e
  usage
end

if args["--help"]
  usage
end

$OPENSHIFT_REPOS = %w{openshift_client openshift_infrastructure openshift_jbosseap openshift_node}
$SAFE_REPOS = $OPENSHIFT_REPOS + %w{rhel6}

#`yum makecache`

repoid_flags = $OPENSHIFT_REPOS.map {|r| "--repoid=#{r}" }.join(" ")
repoquery_cmd = "repoquery --cache #{repoid_flags} --all --qf='%{name}'"
$stderr.puts "Running: #{repoquery_cmd}" if args['--debug']
openshift_packages = `#{repoquery_cmd}`.split

# Any non OpenShift repo that provides an OpenShift package should be
# deprioritized
#
# TODO: this script will need to maintain a list of deprecated OpenShift
# packages
repoquery_cmd = "repoquery --cache --whatprovides #{openshift_packages.join(" ")} --qf='%{repoid}' | sort | uniq"
$stderr.puts "Running: #{repoquery_cmd}" if args['--debug']
repos_found = `#{repoquery_cmd}`.split("\n")

if args["--exhaustive"]
  repoquery_cmd = "repoquery --cache --requires --resolve #{openshift_packages.join(" ")} --qf='%{repoid}' | sort | uniq"
  # merge these with the repos we previously found
  repos_found |= `#{repoquery_cmd}`.split("\n")
end

puts "Repositories to deprioritize:"
bad_repos = repos_found - $SAFE_REPOS
pp bad_repos
