class KafkaExporter < Formula
  desc "Prometheus exporter for kafka metrics"
  homepage "https://prometheus.io/"
  url "https://github.com/danielqsj/kafka_exporter/releases/download/v1.7.0/kafka_exporter-1.7.0.darwin-arm64.tar.gz"
  sha256 "4207821f9936ded1614768185dc69b808cba6a9b38144c70490b049d56e4ae34"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on arch: :arm64

  def install
    bin.install "kafka_exporter"

    touch etc / "kafka_exporter.args"

    (bin / "kafka_exporter_brew_services").write <<~EOS
      #!/bin/bash
      exec #{bin}/kafka_exporter $(<#{etc}/kafka_exporter.args)
    EOS
  end

  def caveats
    <<~EOS
      When run from `brew services`, `kafka_exporter` is run from
      `kafka_exporter_brew_services` and uses the flags in:
        #{etc}/kafka_exporter.args
    EOS
  end

  service do
    run [opt_bin / "kafka_exporter_brew_services"]
    keep_alive false
    log_path var / "log/kafka_exporter.log"
    error_log_path var / "log/kafka_exporter.err.log"
  end

  test do
    assert_match "kafka_exporter", shell_output("#{bin}/kafka_exporter --version 2>&1")

    fork { exec bin / "kafka_exporter" }
    sleep 2
    assert_match "# HELP", shell_output("curl -s localhost:9308/metrics")
  end
end
