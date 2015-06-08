require 'formula'

class Libogg < Formula
  desc "Ogg Bitstream Library"
  homepage 'https://www.xiph.org/ogg/'
  url 'http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz'
  sha1 'df7f3977bbeda67306bc2a427257dd7375319d7d'

  bottle do
    cellar :any
    sha1 "103ee41d6c42015473a4d13b010c33d5dca29f64" => :yosemite
    sha1 "7fcbece23ab93ac6d107625aae32e966615661d1" => :mavericks
    sha1 "ba0b0f47f7043e711eb8ab3719623d15395440ab" => :mountain_lion
    sha1 "e5f0cb6f5b1546e8073cdaa9b09b65b8b7c0d696" => :lion
  end

  head do
    url 'https://svn.xiph.org/trunk/ogg'

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  option :universal
  option "with-10.6", "support OSX 10.6 and up"
  option "with-10.7", "support OSX 10.7 and up"
  option "with-10.8", "support OSX 10.8 and up"
  option "with-10.9", "support OSX 10.9 and up"

  def install
    ENV.universal_binary if build.universal?
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.6' if build.with? "10.6"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.7' if build.with? "10.7"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.8' if build.with? "10.8"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.9' if build.with? "10.9"

    system "./autogen.sh" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make"
    ENV.deparallelize
    system "make install"
  end
end
