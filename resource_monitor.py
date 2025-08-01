#!/usr/bin/env python3
"""
System Resource Monitor
Monitors CPU, GPU, RAM, VRAM, and temperature metrics.
Uploads data to S3 bucket every second.
"""

import json
import time
import os
import sys
from datetime import datetime
from typing import Dict, Any, Optional
import logging

import psutil
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from dotenv import load_dotenv

try:
    import pynvml
    NVIDIA_AVAILABLE = True
except ImportError:
    NVIDIA_AVAILABLE = False
    print("Warning: nvidia-ml-py not available. GPU monitoring disabled.")

# Load environment variables
load_dotenv()

# Configure logging
log_file = os.getenv('LOG_FILE', '/app/logs/resourcemonitor.log')
# Ensure log directory exists
os.makedirs(os.path.dirname(log_file), exist_ok=True)

# Check if we can write to the log file location
try:
    with open(log_file, 'a') as f:
        pass
except (PermissionError, OSError):
    # Fallback to current directory if we can't write to the configured location
    log_file = 'resourcemonitor.log'

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class ResourceMonitor:
    """System resource monitoring class."""
    
    def __init__(self):
        """Initialize the resource monitor."""
        self.s3_bucket = os.getenv('S3_BUCKET_NAME')
        if not self.s3_bucket:
            raise ValueError("S3_BUCKET_NAME environment variable not set")
        
        # Initialize S3 client
        try:
            self.s3_client = boto3.client('s3')
            # Test S3 connection
            self.s3_client.head_bucket(Bucket=self.s3_bucket)
            logger.info(f"Successfully connected to S3 bucket: {self.s3_bucket}")
        except NoCredentialsError:
            logger.error("AWS credentials not found")
            raise
        except ClientError as e:
            logger.error(f"Failed to connect to S3 bucket {self.s3_bucket}: {e}")
            raise
        
        # Initialize NVIDIA GPU monitoring if available
        if NVIDIA_AVAILABLE:
            try:
                pynvml.nvmlInit()
                self.gpu_count = pynvml.nvmlDeviceGetCount()
                logger.info(f"Initialized NVIDIA monitoring for {self.gpu_count} GPU(s)")
            except Exception as e:
                logger.warning(f"Failed to initialize NVIDIA monitoring: {e}")
                self.gpu_count = 0
        else:
            self.gpu_count = 0
    
    def get_cpu_info(self) -> Dict[str, Any]:
        """Get CPU usage and temperature information."""
        cpu_info = {
            'usage_percent': psutil.cpu_percent(interval=1),
            'usage_per_core': psutil.cpu_percent(interval=1, percpu=True),
            'frequency': psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None,
            'count_logical': psutil.cpu_count(logical=True),
            'count_physical': psutil.cpu_count(logical=False),
        }
        
        # Try to get CPU temperature
        try:
            temps = psutil.sensors_temperatures()
            if temps:
                cpu_temps = []
                for name, entries in temps.items():
                    for entry in entries:
                        if 'cpu' in name.lower() or 'core' in entry.label.lower():
                            cpu_temps.append({
                                'sensor': f"{name}_{entry.label}",
                                'temperature': entry.current,
                                'high': entry.high,
                                'critical': entry.critical
                            })
                cpu_info['temperatures'] = cpu_temps
        except (AttributeError, OSError):
            cpu_info['temperatures'] = None
            logger.debug("CPU temperature monitoring not available")
        
        return cpu_info
    
    def get_memory_info(self) -> Dict[str, Any]:
        """Get RAM usage information."""
        virtual_mem = psutil.virtual_memory()
        swap_mem = psutil.swap_memory()
        
        return {
            'virtual': {
                'total': virtual_mem.total,
                'available': virtual_mem.available,
                'used': virtual_mem.used,
                'percent': virtual_mem.percent,
                'free': virtual_mem.free,
                'active': getattr(virtual_mem, 'active', None),
                'inactive': getattr(virtual_mem, 'inactive', None),
                'buffers': getattr(virtual_mem, 'buffers', None),
                'cached': getattr(virtual_mem, 'cached', None)
            },
            'swap': {
                'total': swap_mem.total,
                'used': swap_mem.used,
                'free': swap_mem.free,
                'percent': swap_mem.percent
            }
        }
    
    def get_gpu_info(self) -> Optional[Dict[str, Any]]:
        """Get NVIDIA GPU usage and VRAM information."""
        if not NVIDIA_AVAILABLE or self.gpu_count == 0:
            return None
        
        gpu_info = []
        
        try:
            for i in range(self.gpu_count):
                handle = pynvml.nvmlDeviceGetHandleByIndex(i)
                
                # Get GPU name
                name = pynvml.nvmlDeviceGetName(handle).decode('utf-8')
                
                # Get memory info
                mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
                
                # Get utilization
                util = pynvml.nvmlDeviceGetUtilizationRates(handle)
                
                # Get temperature
                try:
                    temp = pynvml.nvmlDeviceGetTemperature(handle, pynvml.NVML_TEMPERATURE_GPU)
                except:
                    temp = None
                
                # Get power usage
                try:
                    power = pynvml.nvmlDeviceGetPowerUsage(handle) / 1000.0  # Convert to watts
                except:
                    power = None
                
                # Get fan speed
                try:
                    fan_speed = pynvml.nvmlDeviceGetFanSpeed(handle)
                except:
                    fan_speed = None
                
                gpu_info.append({
                    'index': i,
                    'name': name,
                    'memory': {
                        'total': mem_info.total,
                        'used': mem_info.used,
                        'free': mem_info.free,
                        'percent': (mem_info.used / mem_info.total) * 100
                    },
                    'utilization': {
                        'gpu': util.gpu,
                        'memory': util.memory
                    },
                    'temperature': temp,
                    'power_usage_watts': power,
                    'fan_speed_percent': fan_speed
                })
                
        except Exception as e:
            logger.error(f"Error getting GPU info: {e}")
            return None
        
        return gpu_info
    
    def collect_metrics(self) -> Dict[str, Any]:
        """Collect all system metrics."""
        timestamp = datetime.utcnow()
        
        metrics = {
            'timestamp': timestamp.isoformat() + 'Z',
            'hostname': os.uname().nodename,
            'cpu': self.get_cpu_info(),
            'memory': self.get_memory_info(),
            'gpu': self.get_gpu_info()
        }
        
        return metrics
    
    def save_to_file(self, metrics: Dict[str, Any], filename: str = None) -> str:
        """Save metrics to a JSON file."""
        if filename is None:
            timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
            filename = f"metrics_{timestamp}.json"
        
        # Use data directory in Docker environment
        data_dir = os.getenv('DATA_DIR', '/app/data')
        os.makedirs(data_dir, exist_ok=True)
        filepath = os.path.join(data_dir, filename)
        
        try:
            with open(filepath, 'w') as f:
                json.dump(metrics, f, indent=2)
            logger.debug(f"Metrics saved to {filepath}")
            return filepath
        except Exception as e:
            logger.error(f"Failed to save metrics to file: {e}")
            raise
    
    def upload_to_s3(self, filepath: str) -> bool:
        """Upload the metrics file to S3."""
        filename = os.path.basename(filepath)
        s3_key = f"metrics/{filename}"
        
        try:
            self.s3_client.upload_file(filepath, self.s3_bucket, s3_key)
            logger.debug(f"Successfully uploaded {filename} to s3://{self.s3_bucket}/{s3_key}")
            return True
        except Exception as e:
            logger.error(f"Failed to upload {filename} to S3: {e}")
            return False
    
    def cleanup_file(self, filepath: str):
        """Remove the local metrics file after upload."""
        try:
            os.remove(filepath)
            logger.debug(f"Cleaned up local file: {filepath}")
        except Exception as e:
            logger.warning(f"Failed to cleanup file {filepath}: {e}")
    
    def run_once(self) -> bool:
        """Run a single monitoring cycle."""
        try:
            # Collect metrics
            metrics = self.collect_metrics()
            
            # Save to file
            filepath = self.save_to_file(metrics)
            
            # Upload to S3
            upload_success = self.upload_to_s3(filepath)
            
            # Cleanup local file
            if upload_success:
                self.cleanup_file(filepath)
            
            logger.info("Monitoring cycle completed successfully")
            return True
            
        except Exception as e:
            logger.error(f"Error in monitoring cycle: {e}")
            return False
    
    def run_continuous(self, interval: float = 1.0):
        """Run continuous monitoring with specified interval."""
        logger.info(f"Starting continuous monitoring with {interval}s interval")
        logger.info(f"Uploading to S3 bucket: {self.s3_bucket}")
        
        while True:
            try:
                self.run_once()
                time.sleep(interval)
            except KeyboardInterrupt:
                logger.info("Monitoring stopped by user")
                break
            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                time.sleep(interval)  # Continue monitoring even after errors


def main():
    """Main entry point."""
    try:
        monitor = ResourceMonitor()
        monitor.run_continuous(interval=1.0)
    except Exception as e:
        logger.error(f"Failed to start resource monitor: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
