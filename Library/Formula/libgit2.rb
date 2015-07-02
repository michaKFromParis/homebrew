class Libgit2 < Formula
  desc "C library of Git core methods that is re-entrant and linkable"
  homepage "https://libgit2.github.com/"
  url "https://github.com/libgit2/libgit2/archive/v0.22.3.tar.gz"
  sha256 "511fe60e7c12c3525b4e0489861e5c1fe0e331d604bee9a3dfb8420c2f288f60"
  head "https://github.com/libgit2/libgit2.git"

  bottle do
    cellar :any
    sha256 "603830401517418d626a040d7d1494aa80c46b820347b3c8400b83829263efad" => :yosemite
    sha256 "515d821769fab481787e1163d178e15c983ed138d1db26ddf07b99dbe640582e" => :mavericks
    sha256 "6dcaefed58204b8893876c8feb68614ef822f601282d54fad456553f41fc7528" => :mountain_lion
  end

  option :universal
  option "with-10.6", "support OSX 10.6 and up"
  option "with-10.7", "support OSX 10.7 and up"
  option "with-10.8", "support OSX 10.8 and up"
  option "with-10.9", "support OSX 10.9 and up"

  depends_on "cmake" => :build
  depends_on "libssh2" => :optional
  depends_on "openssl"

  def install
    args = std_cmake_args
    args << "-DBUILD_CLAR=NO" # Don't build tests.

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
