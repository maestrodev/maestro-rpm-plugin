require 'maestro_plugin'
require 'maestro_shell'

module MaestroDev
  module Plugin
    class RpmWorker < Maestro::MaestroWorker
  
      def build  
        errors = validate_build_parameters
  
        # Shell execution
        command = "cd #{@path} && #{@rpmbuild_executable} -bb #{@macros_s} #{@buildroot_s} #{@define_s} #{@rpmbuild_options} #{@specfile}"
        set_field("command", command)

        shell = Maestro::Util::Shell.new
        shell.create_script(command)
        write_output("\nRunning command:\n----------\n#{command.chomp}\n----------\n")
        shell.run_script_with_delegate(self, :on_output)
        raise PluginError, "Error building rpm" unless shell.exit_code.success?
      end
  
      def createrepo
        errors = validate_createrepo_parameters
    
        # Shell execution
        command = "#{@createrepo_executable} #{@options.join(' ')} #{@repo_dir}"
        set_field("command", command)
  
        shell = Maestro::Util::Shell.new
        shell.create_script(command)
        write_output("\nRunning command:\n----------\n#{command.chomp}\n----------\n")
        shell.run_script_with_delegate(self, :on_output)
        raise PluginError, "Error creting repo" unless shell.exit_code.success?
      end
  
      def on_output(text)
        write_output(text, :buffer => true)
      end
        
      ###########
      # PRIVATE #
      ###########
      private
  
      def validate_createrepo_parameters
        errors = []

        @createrepo_executable = get_field('createrepo_executable', 'createrepo')
        @repo_dir = get_field('repo_dir', '')
        @options = get_field('createrepo_options', [])

        errors << 'missing field repo_dir' if @repo_dir.empty?

        raise ConfigError, "Config Errors: #{errors.join(', ')}" unless errors.empty?
      end

      def validate_build_parameters
        errors = []

        @rpmbuild_executable = get_field('rpmbuild_executable', 'rpm')
        @specfile = get_field('specfile', '')
        @defines = get_field('defines', [])
        @macros = get_field('macros', '')
        @buildroot = get_field('buildroot', '')
        @rpmbuild_options = get_field('rpmbuild_options', '')
        @path = get_field('path', get_field('scm_path', ''))

        @define_s = @defines.empty? ? "" : @defines.map{|d| "--define \"#{d}\""}.join(" ")
        @macros_s = @macros.empty? ? "" : "--macros #{@macros}"
        @buildroot_s = @buildroot.empty? ? "" : "--buildroot #{@buildroot}"
  
        errors << 'missing field specfile' if @specfile.empty?
        errors << 'missing field path' if @path.empty?

        raise ConfigError, "Config Errors: #{errors.join(', ')}" unless errors.empty?
      end
    end
  end
end
