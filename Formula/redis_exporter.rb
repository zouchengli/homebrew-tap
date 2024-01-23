class RedisExporter < Formula
  desc "Prometheus exporter for redis metrics"
  homepage "https://prometheus.io/"
  url "https://github.com/oliver006/redis_exporter/releases/download/v1.56.0/redis_exporter-v1.56.0.darwin-arm64.tar.gz"
  sha256 "7354cce48ed7ced666ccd69aca4223631257d3c4b7525ecca4da02126b4758d3"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on arch: :arm64

  def install
    bin.install "redis_exporter"

    touch etc / "redis_exporter.args"

    (bin / "redis_exporter_brew_services").write <<~EOS
      #!/bin/bash
      exec #{bin}/redis_exporter $(<#{etc}/redis_exporter.args)
    EOS
  end

  def caveats
    <<~EOS
      When run from `brew services`, `redis_exporter` is run from
      `redis_exporter_brew_services` and uses the flags in:
        #{etc}/redis_exporter.args
    EOS
  end

  service do
    run [opt_bin / "redis_exporter_brew_services"]
    keep_alive false
    log_path var / "log/redis_exporter.log"
    error_log_path var / "log/redis_exporter.err.log"
  end

  test do
    assert_match "redis_exporter", shell_output("#{bin}/redis_exporter --version 2>&1")

    fork { exec bin / "redis_exporter" }
    sleep 2
    assert_match "# HELP", shell_output("curl -s localhost:9121/metrics")
  end
end
