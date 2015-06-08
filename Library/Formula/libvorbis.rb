require 'formula'

class Libvorbis < Formula
  desc "Vorbis General Audio Compression Codec"
  homepage 'http://vorbis.com'
  url 'http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.xz'
  sha256 '54f94a9527ff0a88477be0a71c0bab09a4c3febe0ed878b24824906cd4b0e1d1'

  bottle do
    cellar :any
    sha1 "241550d9dc1c52eecfe2ca63d8609c1e8cf4d5fb" => :yosemite
    sha1 "b216293debbca8baa7bfa848b81cb07e664be847" => :mavericks
    sha1 "44ac5cf5991f063d5ed105379fceb84cd1ef8330" => :mountain_lion
  end

  head do
    url 'http://svn.xiph.org/trunk/vorbis'

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  option :universal
  option "with-10.6", "support OSX 10.6 and up"
  option "with-10.7", "support OSX 10.7 and up"
  option "with-10.8", "support OSX 10.8 and up"
  option "with-10.9", "support OSX 10.9 and up"

  depends_on 'pkg-config' => :build
  depends_on 'libogg'

  def install
    ENV.universal_binary if build.universal?
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.6' if build.with? "10.6"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.7' if build.with? "10.7"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.8' if build.with? "10.8"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.9' if build.with? "10.9"

    system "./autogen.sh" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
  end
end
