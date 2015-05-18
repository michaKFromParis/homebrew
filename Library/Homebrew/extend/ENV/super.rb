require 'os/mac'
require 'extend/ENV/shared'

### Why `superenv`?
# 1) Only specify the environment we need (NO LDFLAGS for cmake)
# 2) Only apply compiler specific options when we are calling that compiler
# 3) Force all incpaths and libpaths into the cc instantiation (less bugs)
# 4) Cater toolchain usage to specific Xcode versions
# 5) Remove flags that we don't want or that will break builds
# 6) Simpler code
# 7) Simpler formula that *just work*
# 8) Build-system agnostic configuration of the tool-chain

module Superenv
  include SharedEnvExtension

  attr_accessor :keg_only_deps, :deps, :x11
  alias_method :x11?, :x11

  def self.extended(base)
    base.keg_only_deps = []
    base.deps = []
  end

  def self.bin
    (HOMEBREW_REPOSITORY/"Library/ENV").subdirs.reject { |d| d.basename.to_s > MacOS::Xcode.version }.max
  end

  def reset
    super
    # Configure scripts generated by autoconf 2.61 or later export as_nl, which
    # we use as a heuristic for running under configure
    delete("as_nl")
  end

  def setup_build_environment(formula=nil)
    super
    send(compiler)

    self['MAKEFLAGS'] ||= "-j#{determine_make_jobs}"
    self['PATH'] = determine_path
    self['PKG_CONFIG_PATH'] = determine_pkg_config_path
    self['PKG_CONFIG_LIBDIR'] = determine_pkg_config_libdir
    self['HOMEBREW_CCCFG'] = determine_cccfg
    self['HOMEBREW_OPTIMIZATION_LEVEL'] = 'Os'
    self['HOMEBREW_BREW_FILE'] = HOMEBREW_BREW_FILE.to_s
    self['HOMEBREW_PREFIX'] = HOMEBREW_PREFIX.to_s
    self['HOMEBREW_CELLAR'] = HOMEBREW_CELLAR.to_s
    self['HOMEBREW_TEMP'] = HOMEBREW_TEMP.to_s
    self['HOMEBREW_SDKROOT'] = effective_sysroot
    self['HOMEBREW_OPTFLAGS'] = determine_optflags
    self['HOMEBREW_ARCHFLAGS'] = ''
    self['CMAKE_PREFIX_PATH'] = determine_cmake_prefix_path
    self['CMAKE_FRAMEWORK_PATH'] = determine_cmake_frameworks_path
    self['CMAKE_INCLUDE_PATH'] = determine_cmake_include_path
    self['CMAKE_LIBRARY_PATH'] = determine_cmake_library_path
    self['ACLOCAL_PATH'] = determine_aclocal_path
    self['M4'] = MacOS.locate("m4") if deps.include? "autoconf"
    self["HOMEBREW_ISYSTEM_PATHS"] = determine_isystem_paths
    self["HOMEBREW_INCLUDE_PATHS"] = determine_include_paths
    self["HOMEBREW_LIBRARY_PATHS"] = determine_library_paths

    # On 10.9, the tools in /usr/bin proxy to the active developer directory.
    # This means we can use them for any combination of CLT and Xcode.
    self["HOMEBREW_PREFER_CLT_PROXIES"] = "1" if MacOS.version >= "10.9"

    # The HOMEBREW_CCCFG ENV variable is used by the ENV/cc tool to control
    # compiler flag stripping. It consists of a string of characters which act
    # as flags. Some of these flags are mutually exclusive.
    #
    # O - Enables argument refurbishing. Only active under the
    #     make/bsdmake wrappers currently.
    # x - Enable C++11 mode.
    # g - Enable "-stdlib=libc++" for clang.
    # h - Enable "-stdlib=libstdc++" for clang.
    # K - Don't strip -arch <arch>, -m32, or -m64
    #
    # On 10.8 and newer, these flags will also be present:
    # s - apply fix for sed's Unicode support
    # a - apply fix for apr-1-config path
  end

  private

  def cc= val
    self["HOMEBREW_CC"] = super
  end

  def cxx= val
    self["HOMEBREW_CXX"] = super
  end

  def effective_sysroot
    MacOS::Xcode.without_clt? ? MacOS.sdk_path.to_s : nil
  end

  def determine_cxx
    determine_cc.to_s.gsub('gcc', 'g++').gsub('clang', 'clang++')
  end

  def determine_path
    paths = [Superenv.bin]

    # Formula dependencies can override standard tools.
    paths += deps.map { |dep| "#{HOMEBREW_PREFIX}/opt/#{dep}/bin" }

    # On 10.9, there are shims for all tools in /usr/bin.
    # On 10.7 and 10.8 we need to add these directories ourselves.
    if MacOS::Xcode.without_clt? && MacOS.version <= "10.8"
      paths << "#{MacOS::Xcode.prefix}/usr/bin"
      paths << "#{MacOS::Xcode.toolchain_path}/usr/bin"
    end

    paths << MacOS::X11.bin.to_s if x11?
    paths += %w{/usr/bin /bin /usr/sbin /sbin}

    # Homebrew's apple-gcc42 will be outside the PATH in superenv,
    # so xcrun may not be able to find it
    case homebrew_cc
    when "gcc-4.2"
      begin
       apple_gcc42 = Formulary.factory('apple-gcc42')
      rescue FormulaUnavailableError
      end
      paths << apple_gcc42.opt_bin.to_s if apple_gcc42
    when GNU_GCC_REGEXP
      gcc_formula = gcc_version_formula($1)
      paths << gcc_formula.opt_bin.to_s
    end

    paths.to_path_s
  end

  def determine_pkg_config_path
    paths  = deps.map{|dep| "#{HOMEBREW_PREFIX}/opt/#{dep}/lib/pkgconfig" }
    paths += deps.map{|dep| "#{HOMEBREW_PREFIX}/opt/#{dep}/share/pkgconfig" }
    paths.to_path_s
  end

  def determine_pkg_config_libdir
    paths = %W{/usr/lib/pkgconfig #{HOMEBREW_LIBRARY}/ENV/pkgconfig/#{MacOS.version}}
    paths << "#{MacOS::X11.lib}/pkgconfig" << "#{MacOS::X11.share}/pkgconfig" if x11?
    paths.to_path_s
  end

  def determine_aclocal_path
    paths = keg_only_deps.map{|dep| "#{HOMEBREW_PREFIX}/opt/#{dep}/share/aclocal" }
    paths << "#{HOMEBREW_PREFIX}/share/aclocal"
    paths << "#{MacOS::X11.share}/aclocal" if x11?
    paths.to_path_s
  end

  def determine_isystem_paths
    paths = []
    paths << "#{HOMEBREW_PREFIX}/include"
    paths << "#{effective_sysroot}/usr/include/libxml2" unless deps.include? "libxml2"
    paths << "#{effective_sysroot}/usr/include/apache2" if MacOS::Xcode.without_clt?
    paths << MacOS::X11.include.to_s << "#{MacOS::X11.include}/freetype2" if x11?
    paths << "#{effective_sysroot}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers"
    paths.to_path_s
  end

  def determine_include_paths
    paths = keg_only_deps.map { |dep| "#{HOMEBREW_PREFIX}/opt/#{dep}/include" }

    # https://github.com/Homebrew/homebrew/issues/38514
    if MacOS::CLT.installed? && MacOS.active_developer_dir.include?("CommandLineTools") &&
       MacOS::CLT.version == "6.3.0.0.1.1428348375"
      paths << "#{HOMEBREW_LIBRARY}/ENV/include/6.3"
    end

    paths.to_path_s
  end

  def determine_library_paths
    paths = keg_only_deps.map { |dep| "#{HOMEBREW_PREFIX}/opt/#{dep}/lib" }
    paths << "#{HOMEBREW_PREFIX}/lib"
    paths << MacOS::X11.lib.to_s if x11?
    paths << "#{effective_sysroot}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries"
    paths.to_path_s
  end

  def determine_cmake_prefix_path
    paths = keg_only_deps.map { |dep| "#{HOMEBREW_PREFIX}/opt/#{dep}" }
    paths << HOMEBREW_PREFIX.to_s
    paths.to_path_s
  end

  def determine_cmake_include_path
    paths = []
    paths << "#{effective_sysroot}/usr/include/libxml2" unless deps.include? "libxml2"
    paths << "#{effective_sysroot}/usr/include/apache2" if MacOS::Xcode.without_clt?
    paths << MacOS::X11.include.to_s << "#{MacOS::X11.include}/freetype2" if x11?
    paths << "#{effective_sysroot}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers"
    paths.to_path_s
  end

  def determine_cmake_library_path
    paths = []
    paths << MacOS::X11.lib.to_s if x11?
    paths << "#{effective_sysroot}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries"
    paths.to_path_s
  end

  def determine_cmake_frameworks_path
    paths = deps.map { |dep| "#{HOMEBREW_PREFIX}/opt/#{dep}/Frameworks" }
    paths << "#{effective_sysroot}/System/Library/Frameworks" if MacOS::Xcode.without_clt?
    paths.to_path_s
  end

  def determine_make_jobs
    if (j = self['HOMEBREW_MAKE_JOBS'].to_i) < 1
      Hardware::CPU.cores
    else
      j
    end
  end

  def determine_optflags
    if ARGV.build_bottle?
      arch = ARGV.bottle_arch || Hardware.oldest_cpu
      Hardware::CPU.optimization_flags.fetch(arch)
    elsif Hardware::CPU.intel? && !Hardware::CPU.sse4?
      Hardware::CPU.optimization_flags.fetch(Hardware.oldest_cpu)
    elsif compiler == :clang
      "-march=native"
    # This is mutated elsewhere, so return an empty string in this case
    else
      ""
    end
  end

  def determine_cccfg
    s = ""
    # Fix issue with sed barfing on unicode characters on Mountain Lion
    s << 's' if MacOS.version >= :mountain_lion
    # Fix issue with >= 10.8 apr-1-config having broken paths
    s << 'a' if MacOS.version >= :mountain_lion
    s
  end

  public

  # Removes the MAKEFLAGS environment variable, causing make to use a single job.
  # This is useful for makefiles with race conditions.
  # When passed a block, MAKEFLAGS is removed only for the duration of the block and is restored after its completion.
  # Returns the value of MAKEFLAGS.
  def deparallelize
    old = delete('MAKEFLAGS')
    if block_given?
      begin
        yield
      ensure
        self['MAKEFLAGS'] = old
      end
    end

    old
  end
  alias_method :j1, :deparallelize

  def make_jobs
    self['MAKEFLAGS'] =~ /-\w*j(\d)+/
    [$1.to_i, 1].max
  end

  def universal_binary
    self['HOMEBREW_ARCHFLAGS'] = Hardware::CPU.universal_archs.as_arch_flags

    # GCC doesn't accept "-march" for a 32-bit CPU with "-arch x86_64"
    if compiler != :clang && Hardware.is_32_bit?
      self['HOMEBREW_OPTFLAGS'] = self['HOMEBREW_OPTFLAGS'].sub(
        /-march=\S*/,
        "-Xarch_#{Hardware::CPU.arch_32_bit} \\0"
      )
    end
  end

  def permit_arch_flags
    append "HOMEBREW_CCCFG", "K"
  end

  def m32
    append "HOMEBREW_ARCHFLAGS", "-m32"
  end

  def m64
    append "HOMEBREW_ARCHFLAGS", "-m64"
  end

  def cxx11
    case homebrew_cc
    when "clang"
      append 'HOMEBREW_CCCFG', "x", ''
      append 'HOMEBREW_CCCFG', "g", ''
    when /gcc-(4\.(8|9)|5)/
      append 'HOMEBREW_CCCFG', "x", ''
    else
      raise "The selected compiler doesn't support C++11: #{homebrew_cc}"
    end
  end

  def libcxx
    append "HOMEBREW_CCCFG", "g", "" if compiler == :clang
  end

  def libstdcxx
    append "HOMEBREW_CCCFG", "h", "" if compiler == :clang
  end

  def refurbish_args
    append 'HOMEBREW_CCCFG', "O", ''
  end

  %w{O3 O2 O1 O0 Os}.each do |opt|
    define_method opt do
      self['HOMEBREW_OPTIMIZATION_LEVEL'] = opt
    end
  end

  def noop(*args); end
  noops = []

  # These methods are no longer necessary under superenv, but are needed to
  # maintain an interface compatible with stdenv.
  noops.concat %w{fast O4 Og libxml2 set_cpu_flags macosxsdk remove_macosxsdk}

  # These methods provide functionality that has not yet been ported to
  # superenv.
  noops.concat %w{gcc_4_0_1 minimal_optimization no_optimization enable_warnings}

  noops.each { |m| alias_method m, :noop }
end


class Array
  def to_path_s
    map(&:to_s).uniq.select{|s| File.directory? s }.join(File::PATH_SEPARATOR).chuzzle
  end
end
