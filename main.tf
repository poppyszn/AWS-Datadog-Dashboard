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
  api_url = "<datadog_api_url>"
}


resource "aws_instance" "base" {
  # count         = 1 # Incase we need to deploy multiple environments
  ami           = "ami-0faab6bdbac9486fb" # This image is for Ubuntu
  instance_type = "t2.micro"
  tags = {
    Name = "MyUbuntuDevEnv"
    env  = "staging"
  }
}

resource "datadog_monitor" "cpumonitor" {
  # count   = length(aws_instance.base)
  name    = "cpu monitor ${aws_instance.base.id}"
  type    = "metric alert"
  message = "CPU usage alert"
  query   = "avg(last_1m):avg:system.cpu.system{host:${aws_instance.base.id}} by {host} > 4"

  monitor_thresholds {
    warning  = 2
    critical = 4
  }
}

resource "datadog_dashboard" "ordered_dashboard" {
  title       = "Server Monitoring Dashboard"
  description = "Dashboard for monitoring server metrics"
  layout_type = "ordered"

  widget {
    alert_graph_definition {
      alert_id  = datadog_monitor.cpumonitor.id
      viz_type  = "timeseries"
      title     = "CPU Usage on ${aws_instance.base.tags.Name}"
      live_span = "1h"
    }
  }
  

  widget {
    query_value_definition {
      request {
        q          = "avg:system.mem.used{env:staging}"
        aggregator = "sum"
        conditional_formats {
          comparator = "<"
          value      = "0.75"
          palette    = "white_on_green"
        }
        conditional_formats {
          comparator = ">"
          value      = "0.75"
          palette    = "white_on_red"
        }
      }
      autoscale   = true
      custom_unit = "xx"
      precision   = "4"
      text_align  = "right"
      title       = "Memory Usage"
      live_span   = "1h"
    }
  }

  widget {
    query_value_definition {
      request {
        q          = "avg:system.disk.used{env:staging}"
        aggregator = "sum"
        conditional_formats {
          comparator = "<"
          value      = "0.75"
          palette    = "white_on_green"
        }
        conditional_formats {
          comparator = ">"
          value      = "0.75"
          palette    = "white_on_red"
        }
      }
      autoscale   = true
      custom_unit = "xx"
      precision   = "4"
      text_align  = "right"
      title       = "Disk Usage"
      live_span   = "1h"
    }
  }

  widget {
    query_value_definition {
      request {
        q          = "avg:system.net.bytes_rcvd{env:staging}, avg:system.net.bytes_sent{env:staging}"
        aggregator = "sum"
        conditional_formats {
          comparator = "<"
          value      = "0.75"
          palette    = "white_on_green"
        }
        conditional_formats {
          comparator = ">"
          value      = "0.75"
          palette    = "white_on_red"
        }
      }
      autoscale   = true
      custom_unit = "xx"
      precision   = "4"
      text_align  = "right"
      title       = "Network Traffic"
      live_span   = "1h"
    }
  }
}