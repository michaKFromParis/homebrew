require 'formula'

class Libvorbis < Formula
  homepage 'http://vorbis.com'
  url 'http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.xz'
  sha1 'b99724acdf3577982b3146b9430d765995ecf9e1'

  bottle do
    cellar :any
    sha1 "d782a644646132fe3c583afc4db34a681a13f904" => :yosemite
    sha1 "5888cafaeb4bb6001a24ceab46d993f104b0adc3" => :mavericks
    sha1 "72fe81e0d9b761954c059e6a5bdd73379eecc33e" => :mountain_lion
    sha1 "49865744038d60add35f19e123a43c3cce6b30f8" => :lion
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
