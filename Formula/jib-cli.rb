class JibCli < Formula
  desc "Container image build tool"
  homepage "https://github.com/GoogleContainerTools/jib"

  version "0.13.0"
  url "https://github.com/GoogleContainerTools/jib/releases/download/v#{version}-cli/jib-jre-#{version}.zip"
  sha256 "e8f6a4766221e6d3817226b8ee14792c4553e5605e79a48558f0d3bef21e0461"
  license "Apache-2.0"

  resource "provenance" do
    url "https://github.com/GoogleContainerTools/jib/releases/download/v#{version}-cli/jib-jre-#{version}.zip.intoto.jsonl"
    sha256 "1b42e4acdd9fb1251846168e51f30f94ae09f59d84bc3cef8a197efcfed58595"
  end

  depends_on "slsa-verifier"
  depends_on "openjdk"

  def install
    resource("provenance").stage do
      provenance_file = Pathname.pwd / "jib-jre-#{version}.zip.intoto.jsonl"
      system "slsa-verifier", "verify-artifact", cached_download,
             "--provenance-path", provenance_file,
             "--source-uri", "github.com/GoogleContainerTools/jib",
             "--source-branch", "master",
             "--build-workflow-input", "release_version=#{version}"
    end

    system "unzip", cached_download
    libexec.install Dir["jib-#{version}/*"]
    bin.install_symlink libexec / "bin/jib"
  end

  test do
    system "#{bin}/jib", "--version"
  end
end
