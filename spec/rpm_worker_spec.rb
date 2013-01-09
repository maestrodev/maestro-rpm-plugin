# Copyright 2012© MaestroDev.  All rights reserved.

require 'spec_helper'
require 'rpm_worker'

describe MaestroDev::RpmWorker do

  before(:each) do
    @worker = MaestroDev::RpmWorker.new
    @worker.stub(:send_workitem_message)
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
        "rpmbuild_options" => "--define \"x y\""
      }
    end

    it 'should build an rpm' do
      wi = Ruote::Workitem.new({"fields" => @fields})
      @worker.stub(:workitem => wi.to_h)
      @worker.stub(:run)
      @worker.stub(:validate_output)
      Maestro::Shell.any_instance.stub(:to_s => "")
      defines_s = @defines.map{|k,v| "--define \"#{k} #{v}\""}.join(" ")
      Maestro::Shell.any_instance.should_receive(:create_script).with(" cd /tmp && rpmbuild -bb --macros #{@macros} --buildroot /tmp/buildroot #{defines_s} --define \"x y\" /tmp/test.spec\n")
      @worker.build

      wi.error.should be_nil
    end

    it 'should fail with empty fields' do
      wi = Ruote::Workitem.new({"fields" => { "path" => "/tmp" } })
      @worker.stub(:workitem => wi.to_h)
      @worker.should_not_receive(:execute)
      @worker.build

      wi.error.should eq("Invalid configuration: missing specfile")
    end
  end

  describe 'createrepo' do

    before(:each) do
      @fields = {
        "createrepo_options" => ["-s sha", "--update"],
        "repo_dir" => "/tmp/repo"
      }
    end

    it 'should create a rpm repository' do
      wi = Ruote::Workitem.new({"fields" => @fields})
      @worker.stub(:workitem => wi.to_h)
      @worker.stub(:run)
      @worker.stub(:validate_output)
      Maestro::Shell.any_instance.stub(:to_s => "")
      Maestro::Shell.any_instance.should_receive(:create_script).with(" createrepo -s sha --update /tmp/repo\n")
      @worker.createrepo

      wi.error.should be_nil
    end

    it 'should fail with empty fields' do
      wi = Ruote::Workitem.new({"fields" => {} })
      @worker.stub(:workitem => wi.to_h)
      @worker.should_not_receive(:execute)
      @worker.createrepo

      wi.error.should eq("Invalid configuration: missing repo_dir")
    end
  end
end
