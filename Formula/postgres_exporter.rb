class PostgresExporter < Formula
  desc "Prometheus exporter for postgres metrics"
  homepage "https://prometheus.io/"
  url "https://github.com/prometheus-community/postgres_exporter/releases/download/v0.15.0/postgres_exporter-0.15.0.darwin-arm64.tar.gz"
  sha256 "a8c3954df5d56cb73e171e785f5ae21729a86b3270e72653d16023fa48605486"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on arch: :arm64

  def install
    bin.install "postgres_exporter"

    touch etc / "postgres_exporter.args"

    (bin / "postgres_exporter_brew_services").write <<~EOS
      #!/bin/bash
      exec #{bin}/postgres_exporter $(<#{etc}/postgres_exporter.args)
    EOS
  end

  def caveats
    <<~EOS
      When run from `brew services`, `postgres_exporter` is run from
      `postgres_exporter_brew_services` and uses the flags in:
        #{etc}/postgres_exporter.args
    EOS
  end

  service do
    run [opt_bin / "postgres_exporter_brew_services"]
    keep_alive false
    log_path var / "log/postgres_exporter.log"
    error_log_path var / "log/postgres_exporter.err.log"
  end

  test do
    assert_match "postgres_exporter", shell_output("#{bin}/postgres_exporter --version 2>&1")

    fork { exec bin / "postgres_exporter" }
    sleep 2
    assert_match "# HELP", shell_output("curl -s localhost:9187/metrics")
  end
end
