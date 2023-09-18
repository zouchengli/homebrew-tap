class Nexus < Formula
  desc "Repository manager for binary software components"
  homepage "https://www.sonatype.org/"
  url "https://github.com/sonatype/nexus-public/archive/refs/tags/release-3.40.1-01.tar.gz"
  sha256 "ec11b10a4f3becc4a7932ffed63f0ce7e7d1451e69bbf5b74623326f47bf7db8"
  license "EPL-1.0"

  # As of writing, upstream is publishing both v2 and v3 releases. The "latest"
  # release on GitHub isn't reliable, as it can point to a release from either
  # one of these major versions depending on which was published most recently.
  livecheck do
    url :stable
    regex(/^(?:release[._-])?v?(\d+(?:[.-]\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, ventura:      "9114db0415c4582f0d1e97e8d7cb8758a1bd2d8094222eae33119f189a3dc85d"
    sha256 cellar: :any_skip_relocation, monterey:     "2d4e904050b210d103b36b47aaed37dcef075aa24b3713d54f040203308cf0e3"
    sha256 cellar: :any_skip_relocation, big_sur:      "ebcc0f030b0c84158344636dc0884d511ad386df587d92725f251725066c7151"
    sha256 cellar: :any_skip_relocation, catalina:     "abc68c0f85091cfd502bf0d4d8b87be1281e63a2350dcaf24b4a407317b14d35"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "dcbe0eea411e6b44a8a86d0ee9ede0b8a1ba15aaeef69cecfb0185b9629f1ac6"
  end

  depends_on "maven" => :build
  #depends_on arch: :x86_64 # openjdk@8 is not supported on ARM
  def caveats
    <<~EOS
      Please install the required Cask manually before using this formula:
        brew install --cask corretto8
        brew install maven --ignore-dependencies
    EOS
  end


  uses_from_macos "unzip" => :build

  def install
    ENV["JAVA_HOME"] = `/usr/libexec/java_home -v 1.8`.chomp
    #system "java", "-version"
    system "mvn", "install", "-DskipTests"
    system "unzip", "-o", "-d", "target", "assemblies/nexus-base-template/target/nexus-base-template-#{version}.zip"

    rm_f Dir["target/nexus-base-template-#{version}/bin/*.bat"]
    rm_f "target/nexus-base-template-#{version}/bin/contrib"
    libexec.install Dir["target/nexus-base-template-#{version}/*"]

    env = {
      JAVA_HOME:  `/usr/libexec/java_home -v 1.8`.chomp,
      KARAF_DATA: "${NEXUS_KARAF_DATA:-#{var}/nexus}",
      KARAF_LOG:  "#{var}/log/nexus",
      KARAF_ETC:  "#{etc}/nexus",
    }

    (bin/"nexus").write_env_script libexec/"bin/nexus", env
  end

  def post_install
    mkdir_p "#{var}/log/nexus" unless (var/"log/nexus").exist?
    mkdir_p "#{var}/nexus" unless (var/"nexus").exist?
    mkdir "#{etc}/nexus" unless (etc/"nexus").exist?
  end

  service do
    run ["/bin/bash", "-c", "ulimit -n 65536 && #{opt_bin}/nexus start && tail -f #{var}/nexus/log/nexus.log"]
    keep_alive true
    log_path var/"log/nexus.log"
    error_log_path var/"log/nexus.log"
  end

  test do
    mkdir "data"
    fork do
      ENV["NEXUS_KARAF_DATA"] = testpath/"data"
      exec "#{bin}/nexus", "server"
    end
    sleep 100
    assert_match "<title>Nexus Repository Manager</title>", shell_output("curl --silent --fail http://localhost:8081")
  end
end
