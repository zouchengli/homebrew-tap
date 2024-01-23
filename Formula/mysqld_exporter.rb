class MysqldExporter < Formula
  desc "Prometheus exporter for mysql metrics"
  homepage "https://prometheus.io/"
  url "https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.1/mysqld_exporter-0.15.1.darwin-arm64.tar.gz"
  sha256 "f38be81951d8b8080f30287e04d241a90107c2f432e3316cf72e92aa3464783a"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on arch: :arm64

  def install
    bin.install "mysqld_exporter"

    touch etc / "mysqld_exporter.args"

    (bin / "mysqld_exporter_brew_services").write <<~EOS
      #!/bin/bash
      exec #{bin}/mysqld_exporter $(<#{etc}/mysqld_exporter.args)
    EOS
  end

  def caveats
    <<~EOS
      When run from `brew services`, `mysqld_exporter` is run from
      `mysqld_exporter_brew_services` and uses the flags in:
        #{etc}/mysqld_exporter.args
    EOS
  end

  service do
    run [opt_bin / "mysqld_exporter_brew_services"]
    keep_alive false
    log_path var / "log/mysqld_exporter.log"
    error_log_path var / "log/mysqld_exporter.err.log"
  end

  test do
    assert_match "mysqld_exporter", shell_output("#{bin}/mysqld_exporter --version 2>&1")

    fork { exec bin / "mysqld_exporter" }
    sleep 2
    assert_match "# HELP", shell_output("curl -s localhost:9104/metrics")
  end
end
