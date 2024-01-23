class ElasticsearchExporter < Formula
  desc "Prometheus exporter for elasticsearch metrics"
  homepage "https://prometheus.io/"
  url "https://github.com/prometheus-community/elasticsearch_exporter/releases/download/v1.7.0/elasticsearch_exporter-1.7.0.darwin-arm64.tar.gz"
  sha256 "6e1dc37da9043822d41392922add5ffdf6ab00257d896adfaa8d8444c36f60ce"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on arch: :arm64

  def install
    bin.install "elasticsearch_exporter"

    touch etc / "elasticsearch_exporter.args"

    (bin / "elasticsearch_exporter_brew_services").write <<~EOS
      #!/bin/bash
      exec #{bin}/elasticsearch_exporter $(<#{etc}/elasticsearch_exporter.args)
    EOS
  end

  def caveats
    <<~EOS
      When run from `brew services`, `elasticsearch_exporter` is run from
      `elasticsearch_exporter_brew_services` and uses the flags in:
        #{etc}/elasticsearch_exporter.args
    EOS
  end

  service do
    run [opt_bin / "elasticsearch_exporter_brew_services"]
    keep_alive false
    log_path var / "log/elasticsearch_exporter.log"
    error_log_path var / "log/elasticsearch_exporter.err.log"
  end

  test do
    assert_match "elasticsearch_exporter", shell_output("#{bin}/elasticsearch_exporter --version 2>&1")

    fork { exec bin / "elasticsearch_exporter" }
    sleep 2
    assert_match "# HELP", shell_output("curl -s localhost:9114/metrics")
  end
end
