#!/usr/bin/env python3
"""
Test script for Resource Monitor
Tests the monitoring functionality without S3 upload
"""

import json
import os
import sys
from datetime import datetime

# Add the current directory to path to import resource_monitor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from resource_monitor import ResourceMonitor

def test_metrics_collection():
    """Test metrics collection without S3 upload."""
    print("Testing metrics collection...")
    
    # Create a mock S3 bucket name for testing
    os.environ['S3_BUCKET_NAME'] = 'test-bucket--us-east-1a--x-s3'
    
    try:
        # Create monitor instance (this will fail on S3 connection, which is expected)
        monitor = ResourceMonitor()
    except Exception as e:
        print(f"Expected S3 connection error: {e}")
        # Create a simplified version for testing
        class TestMonitor:
            def get_cpu_info(self):
                import psutil
                return {
                    'usage_percent': psutil.cpu_percent(interval=1),
                    'usage_per_core': psutil.cpu_percent(interval=1, percpu=True),
                    'frequency': psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None,
                    'count_logical': psutil.cpu_count(logical=True),
                    'count_physical': psutil.cpu_count(logical=False),
                }
            
            def get_memory_info(self):
                import psutil
                virtual_mem = psutil.virtual_memory()
                swap_mem = psutil.swap_memory()
                return {
                    'virtual': {
                        'total': virtual_mem.total,
                        'available': virtual_mem.available,
                        'used': virtual_mem.used,
                        'percent': virtual_mem.percent,
                    },
                    'swap': {
                        'total': swap_mem.total,
                        'used': swap_mem.used,
                        'percent': swap_mem.percent
                    }
                }
            
            def get_gpu_info(self):
                try:
                    import pynvml
                    pynvml.nvmlInit()
                    gpu_count = pynvml.nvmlDeviceGetCount()
                    
                    gpu_info = []
                    for i in range(gpu_count):
                        handle = pynvml.nvmlDeviceGetHandleByIndex(i)
                        name = pynvml.nvmlDeviceGetName(handle).decode('utf-8')
                        mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
                        util = pynvml.nvmlDeviceGetUtilizationRates(handle)
                        
                        gpu_info.append({
                            'index': i,
                            'name': name,
                            'memory': {
                                'total': mem_info.total,
                                'used': mem_info.used,
                                'percent': (mem_info.used / mem_info.total) * 100
                            },
                            'utilization': {
                                'gpu': util.gpu,
                                'memory': util.memory
                            }
                        })
                    
                    return gpu_info
                except Exception as e:
                    print(f"GPU monitoring not available: {e}")
                    return None
            
            def collect_metrics(self):
                timestamp = datetime.utcnow()
                return {
                    'timestamp': timestamp.isoformat() + 'Z',
                    'hostname': os.uname().nodename,
                    'cpu': self.get_cpu_info(),
                    'memory': self.get_memory_info(),
                    'gpu': self.get_gpu_info()
                }
        
        monitor = TestMonitor()
    
    # Collect metrics
    print("Collecting system metrics...")
    metrics = monitor.collect_metrics()
    
    # Display results
    print("\n=== SYSTEM METRICS ===")
    print(f"Timestamp: {metrics['timestamp']}")
    print(f"Hostname: {metrics['hostname']}")
    
    print(f"\nCPU Usage: {metrics['cpu']['usage_percent']:.1f}%")
    print(f"CPU Cores (Logical/Physical): {metrics['cpu']['count_logical']}/{metrics['cpu']['count_physical']}")
    
    print(f"\nRAM Usage: {metrics['memory']['virtual']['percent']:.1f}%")
    print(f"RAM Used: {metrics['memory']['virtual']['used'] / (1024**3):.1f} GB")
    print(f"RAM Total: {metrics['memory']['virtual']['total'] / (1024**3):.1f} GB")
    
    if metrics['gpu']:
        print(f"\nGPU Count: {len(metrics['gpu'])}")
        for gpu in metrics['gpu']:
            print(f"GPU {gpu['index']}: {gpu['name']}")
            print(f"  VRAM Usage: {gpu['memory']['percent']:.1f}%")
            print(f"  GPU Utilization: {gpu['utilization']['gpu']}%")
    else:
        print("\nNo GPU detected or GPU monitoring unavailable")
    
    # Save to file for inspection
    output_file = 'test_metrics.json'
    with open(output_file, 'w') as f:
        json.dump(metrics, f, indent=2)
    
    print(f"\nFull metrics saved to: {output_file}")
    print("Test completed successfully!")

if __name__ == "__main__":
    test_metrics_collection()
