require 'maestro_agent'

module MaestroDev
  class RpmWorker < Maestro::ShellParticipant

    def log(message, exception)
      msg = "#{message}: #{exception.message}\n#{exception.backtrace.join("\n")}"
      Maestro.log.error msg
      set_error(msg)
    end

    def log_output(msg, level=:debug)
      Maestro.log.send(level, msg)
      write_output "#{msg}\n"
    end

    def validate(required_fields)
      errors = []
      required_fields.each{|s|
        errors << "missing #{s}" if get_field(s).nil? || get_field(s).empty?
      }
      unless errors.empty?
        msg = "Invalid configuration: #{errors.join("\n")}"
        Maestro.log.error msg
        set_error msg
      end
      return errors
    end

    def build
      log_output("Starting RPM", :info)

      errors = validate(["specfile"])
      return unless errors.empty?

      defines = get_field('defines') || []
      macros = get_field('macros')
      buildroot = get_field('buildroot')
      define_s = defines.empty? ? "" : defines.map{|d| "--define \"#{d}\""}.join(" ")
      macros_s = macros.nil? ? "" : "--macros #{macros}"
      buildroot_s = buildroot.nil? ? "" : "--buildroot #{buildroot}"

      # Shell execution
      command = "cd #{path()} && rpmbuild -bb #{macros_s} #{buildroot_s} #{define_s} #{get_field('rpmbuild_options')} #{get_field('specfile')}"
      set_field("command_string", command)
      environment = ""
      set_field("environment", environment)

      execute
    end

    def createrepo
      log_output("Starting RPM createrepo", :info)

      errors = validate(["repo_dir"])
      return unless errors.empty?

      options = get_field('createrepo_options') || []

      # Shell execution
      command = "createrepo #{options.join(" ")} #{get_field('repo_dir')}"
      set_field("command_string", command)
      environment = ""
      set_field("environment", environment)

      execute
    end
  end
end
