#!/bin/bash
yum update -y

# Install packages
yum install -y java-11-amazon-corretto aws-cli amazon-cloudwatch-agent docker

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "${project_name}/App",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/app/application.log",
                        "log_group_name": "/aws/ec2/${project_name}/app/application",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create app directory
mkdir -p /opt/app /var/log/app
chown ec2-user:ec2-user /opt/app /var/log/app

# Create simple Java application
cat > /opt/app/SimpleApp.java << 'EOF'
import java.io.*;
import java.net.*;
import java.util.concurrent.*;

public class SimpleApp {
    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        
        server.createContext("/api/health", exchange -> {
            String response = "OK";
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        });
        
        server.createContext("/api/info", exchange -> {
            String response = "{\\"service\\": \\"${project_name}\\", \\"status\\": \\"running\\", \\"timestamp\\": \\"" + 
                            System.currentTimeMillis() + "\\"}";
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        });
        
        server.setExecutor(Executors.newFixedThreadPool(10));
        server.start();
        System.out.println("Server started on port 8080");
    }
}
EOF

# Compile and run the application
cd /opt/app
javac SimpleApp.java

# Create systemd service
cat > /etc/systemd/system/app.service << 'EOF'
[Unit]
Description=${project_name} Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/java SimpleApp
Restart=always
RestartSec=10
StandardOutput=append:/var/log/app/application.log
StandardError=append:/var/log/app/application.log

[Install]
WantedBy=multi-user.target
EOF

# Start the application
systemctl daemon-reload
systemctl start app
systemctl enable app