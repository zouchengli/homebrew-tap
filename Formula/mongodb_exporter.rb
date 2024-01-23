class MongodbExporter < Formula
  desc "Prometheus exporter for mongodb metrics"
  homepage "https://prometheus.io/"
  url "https://github.com/percona/mongodb_exporter/releases/download/v0.40.0/mongodb_exporter-0.40.0.darwin-arm64.tar.gz"
  sha256 "ad3f8dfa300b19e7cb880dd24a96aec010094855cdf4837452e77ff7668c4486"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on arch: :arm64

  def install
    bin.install "mongodb_exporter"

    touch etc / "mongodb_exporter.args"

    (bin / "mongodb_exporter_brew_services").write <<~EOS
      #!/bin/bash
      exec #{bin}/mongodb_exporter $(<#{etc}/mongodb_exporter.args)
    EOS
  end

  def caveats
    <<~EOS
      When run from `brew services`, `mongodb_exporter` is run from
      `mongodb_exporter_brew_services` and uses the flags in:
        #{etc}/mongodb_exporter.args
    EOS
  end

  service do
    run [opt_bin / "mongodb_exporter_brew_services"]
    keep_alive false
    log_path var / "log/mongodb_exporter.log"
    error_log_path var / "log/mongodb_exporter.err.log"
  end

  test do
    assert_match "mongodb_exporter", shell_output("#{bin}/mongodb_exporter --version 2>&1")

    fork { exec bin / "mongodb_exporter" }
    sleep 2
    assert_match "# HELP", shell_output("curl -s localhost:9216/metrics")
  end
end
