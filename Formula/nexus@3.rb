class NexusAT3 < Formula
  desc "Repository manager for binary software components"
  homepage "https://www.sonatype.org/"
  version "3.60.0-02"
  
  if OS.mac?
    url "https://download.sonatype.com/nexus/3/nexus-#{version}-mac.tgz"
    sha256 "1b81b5dbdcc1f79c4116b02887683d435cceb6ad0a7c0ce364ae7ae2ca8bd08f"
  elsif OS.linux?
    url "https://download.sonatype.com/nexus/3/nexus-#{version}-unix.tar.gz"
    sha256 "607f6a6286ae346671f9eb4bf47bb26f4238c7c6d4aeec6b7122c28f558040e3"
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
