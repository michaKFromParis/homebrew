class Libgit2 < Formula
  desc "C library of Git core methods that is re-entrant and linkable"
  homepage "https://libgit2.github.com/"
  url "https://github.com/libgit2/libgit2/archive/v0.23.2.tar.gz"
  sha256 "20c0a6ee92c0e19207dac6ddc336b4ae4a1c4ddf91be0891e4b6e6ccba16df0b"
  head "https://github.com/libgit2/libgit2.git"

  bottle do
    cellar :any
    sha256 "513f1f6dd6877fc7a3503d24638478d3aeacd9ba3256f5a33e39da3bf595390a" => :el_capitan
    sha256 "74d933a78ac7345d427b205a2fd0390e70b039d1512f501d12801befc5c8d66b" => :yosemite
    sha256 "9adb73739615d439375027d9afe05ba2c9dc40389bc62ee838f94340b55c383b" => :mavericks
  end

  option :universal
  option "with-10.6", "support OSX 10.6 and up"
  option "with-10.7", "support OSX 10.7 and up"
  option "with-10.8", "support OSX 10.8 and up"
  option "with-10.9", "support OSX 10.9 and up"

  depends_on "pkg-config" => :build
  depends_on "cmake" => :build
  depends_on "libssh2" => :optional
  depends_on "openssl" if MacOS.version <= :lion # Uses SecureTransport on >10.7

  def install
    args = std_cmake_args
    args << "-DBUILD_CLAR=NO" # Don't build tests.
    args << "-DUSE_SSH=NO" if build.without? "libssh2"

    if build.universal?
      ENV.universal_binary
      args << "-DCMAKE_OSX_ARCHITECTURES=#{Hardware::CPU.universal_archs.as_cmake_arch_flags}"
    end

    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.6' if build.with? "10.6"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.7' if build.with? "10.7"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.8' if build.with? "10.8"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.9' if build.with? "10.9"

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "install"
    end
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <git2.h>

      int main(int argc, char *argv[]) {
        int options = git_libgit2_features();
        return 0;
      }
    EOS
    libssh2 = Formula["libssh2"]
    flags = (ENV.cflags || "").split + (ENV.cppflags || "").split + (ENV.ldflags || "").split
    flags += %W[
      -I#{include}
      -I#{libssh2.opt_include}
      -L#{lib}
      -lgit2
    ]
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
