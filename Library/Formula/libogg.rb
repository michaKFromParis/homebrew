class Libogg < Formula
  desc "Ogg Bitstream Library"
  homepage "https://www.xiph.org/ogg/"
  url "http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz"
  sha256 "e19ee34711d7af328cb26287f4137e70630e7261b17cbe3cd41011d73a654692"

  bottle do
    cellar :any
    sha256 "dde4684a0247e6b6b27025ff66a35035a9c58492516b6d5c227e8be1eb880685" => :el_capitan
    sha256 "5d203c8e978aee2005f8ae4e85ba1e0451d4a29c8d6f878ada8da5d45f60fe84" => :yosemite
    sha256 "eafa300fd404b5f2a48b9327b8cb320712faf228ff2fbfdac53ad99060f82350" => :mavericks
    sha256 "795ebc059c77ca0087ead3f642a888bfc470953c98104dacee5b6e5d7c5aeaa9" => :mountain_lion
    sha256 "b2b1a8a3bf34fd5f7ea7d60a10fe38e3d699b7344a843599938d1669871c9c8a" => :lion
  end

  head do
    url "https://svn.xiph.org/trunk/ogg"

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
    system "make", "install"
  end
end
