class NexusAT3 < Formula
  desc "Repository manager for binary software components"
  homepage "https://www.sonatype.org/"
  version "3.69.0-02"
  
  if OS.mac?
    url "https://download.sonatype.com/nexus/3/nexus-#{version}-java8-mac.tgz"
    sha256 "a8ee60af53db81c2fca1475fe04370a363064609fecd1dba8bba8a586b499a03"
  elsif OS.linux?
    url "https://download.sonatype.com/nexus/3/nexus-#{version}-java8-unix.tar.gz"
    sha256 "29952f663982bd9781d5bc352471727826943452cfe8e9aa0e9b60ad01531d1b"
  else
    odie "Unsupported operating system"
  end

  def caveats
    <<~EOS
    Please install the required Cask manually using this formula:
      brew install --cask corretto8
      csrutil disable
      sudo launchctl limit maxfiles 65536 65536
      For more details, please refer to https://links.sonatype.com/products/nexus/system-reqs#filehandles
    EOS
  end

  def install
    libexec.install Dir["nexus-#{version}/*"]
    cp_r "#{buildpath}/nexus-#{version}/.install4j", "#{libexec}/.install4j"
    inreplace "#{libexec}/bin/nexus.vmoptions", "../sonatype-work/nexus3", "#{var}/nexus3"
    inreplace "#{libexec}/bin/nexus.vmoptions", /^.+\Z/, "\\0\n-XX:-MaxFDLimit"
  end

  def post_install
    mkdir_p "#{var}/log/nexus3" unless (var/"log/nexus3").exist?
    mkdir_p "#{var}/nexus3" unless (var/"nexus3").exist?
    #mkdir "#{etc}/nexus3" unless (etc/"nexus3").exist?
  end

  service do
    run [libexec/"bin/nexus", "run"]
    keep_alive true
    log_path var/"log/nexus3.log"
    error_log_path var/"log/nexus3.log"
  end

end
