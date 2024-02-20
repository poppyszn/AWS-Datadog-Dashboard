terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    datadog = {
      source = "DataDog/datadog"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "datadog" {
  api_key = "<datadog_api_key>"
  app_key = "<datadog_app_key>"
  api_url = "https://app.datadoghq.eu"
}


resource "aws_instance" "base" {
  ami           = "ami-0faab6bdbac9486fb" # This image is for Ubuntu
  instance_type = "t2.micro"
  tags = {
    Name = "MyUbuntuDevEnv"
    env  = "staging"
  }
}

resource "datadog_monitor" "cpumonitor" {
  name    = "cpu monitor ${aws_instance.base.id}"
  type    = "metric alert"
  message = "CPU usage alert"
  query   = "avg(last_1h):avg:system.cpu.system{*} by {host} > 75"

  monitor_thresholds {
    warning  = 50 #in %
    critical = 75 # in %
  }
}

resource "datadog_monitor" "memorymonitor" {
  name    = "memory monitor ${aws_instance.base.id}"
  type    = "metric alert"
  message = "Memory usage alert"
  query   = "avg(last_1h):avg:system.mem.used{*} by {host} > 2000000000"

  monitor_thresholds {
    warning  = 50000000 #in bits
    critical = 2000000000 #in bits
  }
}

resource "datadog_monitor" "diskmonitor" {
  name    = "disk monitor ${aws_instance.base.id}"
  type    = "metric alert"
  message = "Disk usage alert"
  query   = "avg(last_1h):avg:system.disk.used{*} by {host} > 2000000000"

  monitor_thresholds {
    warning  = 999000000 #in bits
    critical = 2000000000 #in bits
  }
}

resource "datadog_dashboard" "ordered_dashboard" {
  title       = "Server Monitoring Dashboard"
  description = "Dashboard for monitoring server metrics"
  layout_type = "ordered"

  widget {
    query_value_definition {
      request {
        q          = "avg:system.uptime{*}"
        aggregator = "avg"
      }
      autoscale  = true
      precision  = "4"
      text_align = "right"
      title      = "System Uptime"
      live_span  = "1h"
    }
  }

  widget {
    alert_graph_definition {
      alert_id  = datadog_monitor.cpumonitor.id
      viz_type  = "timeseries"
      title     = "CPU Usage"
      live_span = "1h"
    }
  }

  widget {
    alert_graph_definition {
      alert_id  = datadog_monitor.memorymonitor.id
      viz_type  = "timeseries"
      title     = "Memory Usage"
      live_span = "1h"
    }
  }

  widget {
    alert_graph_definition {
      alert_id  = datadog_monitor.diskmonitor.id
      viz_type  = "timeseries"
      title     = "Disk Usage"
      live_span = "1h"
    }
  }
}