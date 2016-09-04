class Libsndfile < Formula
  desc "C library for files containing sampled sound"
  homepage "http://www.mega-nerd.com/libsndfile/"
  url "http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.26.tar.gz"
  sha256 "cd6520ec763d1a45573885ecb1f8e4e42505ac12180268482a44b28484a25092"

  bottle do
    cellar :any
    sha256 "14fb9d6ecd9bf39fce4d59b7d772edad94566e60e922724f014f034f7e343992" => :el_capitan
    sha256 "5817f2567471377ce161172d58059cd0cfcbbe9cb1e5f6eb80b501a629d40b5f" => :yosemite
    sha256 "a5700a479cafd48d22e2032d95207abcd2d43fc56015348684522b8a61eb4f04" => :mavericks
  end

  option :universal

  depends_on "pkg-config" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "flac"
  depends_on "libogg"
  depends_on "libvorbis"

  option :universal
  option "with-10.6", "support OSX 10.6 and up"
  option "with-10.7", "support OSX 10.7 and up"
  option "with-10.8", "support OSX 10.8 and up"
  option "with-10.9", "support OSX 10.9 and up"

  # libsndfile doesn't find Carbon.h using XCode 4.3:
  # fixed upstream: https://github.com/erikd/libsndfile/commit/d04e1de82ae0af48fd09d5cb09bf21b4ca8d513c
  patch do
    url "https://gist.githubusercontent.com/metabr/8623583/raw/90966b76c6f52e1293b5303541e1f2d72e2afd08/0001-libsndfile-doesn-t-find-Carbon.h-using-XCode-4.3.patch"
    sha256 "6b5fd749ef3b4990ca011eb65289c369cff82285e99773e4a74de4615f082df5"
  end

  # libsndfile fails to build with libvorbis 1.3.4
  # fixed upstream:
  # https://github.com/erikd/libsndfile/commit/d7cc3dd0a437cfb087e09c80c0b89dfd3ec80a54
  # https://github.com/erikd/libsndfile/commit/700ae0e8f358497dd614bcee8e4b93c629209b37
  # https://github.com/erikd/libsndfile/commit/50d1df56f7f9b90d0fafc618d4947611e9689ae9
  patch do
    url "https://gist.githubusercontent.com/metabr/8623583/raw/cd3540f4abd8521edf0011ab6dd40888cfadfd7a/0002-libsndfile-fails-to-build-with-libvorbis-1.3.4.patch"
    sha256 "00697cfe8e13e6d4b36f6ad6327dd670be5a6542371b2ccabcc3175527731a41"
  end

  def install
    ENV.universal_binary if build.universal?
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.6' if build.with? "10.6"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.7' if build.with? "10.7"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.8' if build.with? "10.8"
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.9' if build.with? "10.9"

    system "autoreconf", "-i"
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end
end
