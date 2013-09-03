# Copyright 2012© MaestroDev.  All rights reserved.

require 'spec_helper'
require 'rpm_worker'

describe MaestroDev::Plugin::RpmWorker do

  before(:each) do
    Maestro::MaestroWorker.mock!
  end

  describe 'build' do

    before(:each) do
      @macros = "/usr/lib/rpm/macros:/usr/lib/rpm/%{_target}/macros:/etc/rpm/macros.*:/etc/rpm/macros:/etc/rpm/%{_target}/macros:~/.rpmmacros:systems/rpmmacros"
      @defines = { "_rpmdir" => "/tmp/rpms", "_sourcedir" => "/tmp/src"}
      @fields = {
        "path" => "/tmp",
        "macros" => @macros,
        "buildroot" => "/tmp/buildroot",
        "defines" => @defines.map{|k,v| "#{k} #{v}"},
        "specfile" => "/tmp/test.spec",
        "rpmbuild_options" => "--define \"x y\"",
        "rpmbuild_executable" => 'echo Happy'
      }
      @workitem = {'fields' => @fields}
    end

    it 'should build an rpm' do
      subject.perform(:build, @workitem)

      defines_s = @defines.map{|k,v| "--define \"#{k} #{v}\""}.join(" ")

      @workitem['fields']['command'].should include(defines_s)
      @workitem['fields']['__error__'].should be_nil
    end

    it 'should fail with empty fields' do
      wi = {"fields" => {} }

      subject.perform(:build, wi)

      wi['fields']['__error__'].should include("missing field specfile")
      wi['fields']['__error__'].should include("missing field path")
    end
  end

  describe 'createrepo' do

    before(:each) do
      @fields = {
        "createrepo_options" => ["-s sha", "--update"],
        "repo_dir" => "/tmp/repo",
        'createrepo_executable' => 'echo Joy'
      }
      @workitem = {'fields' => @fields}
    end

    it 'should create a rpm repository' do
      subject.perform(:createrepo, @workitem)

      @workitem['fields']['__error__'].should be_nil
    end

    it 'should fail with empty fields' do
      wi = {"fields" => {} }
      subject.perform(:createrepo, wi)

      wi['fields']['__error__'].should include("missing field repo_dir")
    end
  end
end
